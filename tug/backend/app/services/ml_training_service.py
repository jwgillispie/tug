# app/services/ml_training_service.py
import asyncio
import logging
import pickle
import os
from datetime import datetime, timedelta, timezone
from typing import Dict, List, Any, Optional, Tuple
from pathlib import Path
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestRegressor, RandomForestClassifier
from sklearn.model_selection import train_test_split, cross_val_score, GridSearchCV
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.metrics import mean_absolute_error, accuracy_score, classification_report
from sklearn.pipeline import Pipeline
from joblib import dump, load

from ..models.user import User
from ..models.activity import Activity
from ..models.value import Value

logger = logging.getLogger(__name__)


class MLTrainingService:
    """Service for training, evaluating, and managing ML models"""
    
    def __init__(self):
        self.models_dir = Path("/tmp/tug_ml_models")
        self.models_dir.mkdir(exist_ok=True)
        
        # Model configurations
        self.model_configs = {
            "habit_formation": {
                "model_type": "classifier",
                "target": "habit_success",
                "features": [
                    'hour', 'day_of_week', 'duration', 'value_importance',
                    'current_streak', 'week_consistency', 'time_since_last_activity'
                ],
                "hyperparameters": {
                    "n_estimators": [50, 100, 200],
                    "max_depth": [5, 10, 15, None],
                    "min_samples_split": [2, 5, 10],
                    "min_samples_leaf": [1, 2, 4]
                }
            },
            "duration_prediction": {
                "model_type": "regressor",
                "target": "duration",
                "features": [
                    'hour', 'day_of_week', 'value_importance',
                    'current_streak', 'avg_duration_week'
                ],
                "hyperparameters": {
                    "n_estimators": [50, 100],
                    "max_depth": [5, 10, None],
                    "min_samples_split": [2, 5],
                    "min_samples_leaf": [1, 2]
                }
            },
            "streak_risk": {
                "model_type": "classifier",
                "target": "streak_break_risk",
                "features": [
                    'time_since_last_activity', 'current_streak', 'week_consistency',
                    'avg_duration_week', 'hour', 'day_of_week'
                ],
                "hyperparameters": {
                    "n_estimators": [50, 100],
                    "max_depth": [5, 10],
                    "min_samples_split": [2, 5],
                    "min_samples_leaf": [1, 2]
                }
            }
        }

    async def train_global_models(self) -> Dict[str, Any]:
        """Train models using data from all users"""
        
        logger.info("Starting global model training")
        training_results = {}
        
        try:
            # Collect training data from all users
            training_data = await self._collect_training_data()
            
            if training_data.empty:
                logger.warning("No training data available")
                return {"error": "Insufficient training data"}
            
            logger.info(f"Collected {len(training_data)} data points for training")
            
            # Train each model
            for model_name, config in self.model_configs.items():
                logger.info(f"Training {model_name} model")
                
                try:
                    result = await self._train_single_model(model_name, config, training_data)
                    training_results[model_name] = result
                    
                    logger.info(f"Successfully trained {model_name}: accuracy={result.get('accuracy', 'N/A')}")
                    
                except Exception as e:
                    logger.error(f"Failed to train {model_name}: {e}")
                    training_results[model_name] = {"error": str(e)}
            
            # Save training metadata
            await self._save_training_metadata(training_results)
            
            return {
                "status": "completed",
                "models_trained": len([r for r in training_results.values() if "error" not in r]),
                "training_data_points": len(training_data),
                "results": training_results,
                "timestamp": datetime.now(timezone.utc)
            }
            
        except Exception as e:
            logger.error(f"Error in global model training: {e}", exc_info=True)
            return {"error": f"Training failed: {str(e)}"}

    async def _collect_training_data(self) -> pd.DataFrame:
        """Collect and prepare training data from all users"""
        
        # Get recent active users (last 30 days)
        cutoff_date = datetime.now(timezone.utc) - timedelta(days=30)
        
        users = await User.find(
            User.last_login >= cutoff_date
        ).limit(1000).to_list()  # Limit for performance
        
        if not users:
            logger.warning("No recent users found for training")
            return pd.DataFrame()
        
        all_training_data = []
        
        for user in users:
            try:
                user_data = await self._extract_user_training_data(user)
                if not user_data.empty:
                    all_training_data.append(user_data)
                    
            except Exception as e:
                logger.warning(f"Failed to extract data for user {user.id}: {e}")
                continue
        
        if not all_training_data:
            return pd.DataFrame()
            
        combined_data = pd.concat(all_training_data, ignore_index=True)
        logger.info(f"Combined training data shape: {combined_data.shape}")
        
        return combined_data

    async def _extract_user_training_data(self, user: User) -> pd.DataFrame:
        """Extract training features and targets for a specific user"""
        
        # Get user activities from last 90 days
        cutoff_date = datetime.now(timezone.utc) - timedelta(days=90)
        
        activities = await Activity.find(
            Activity.user_id == str(user.id),
            Activity.date >= cutoff_date
        ).sort([("date", 1)]).to_list()
        
        if len(activities) < 10:  # Need minimum data for meaningful training
            return pd.DataFrame()
        
        # Get user values
        values = await Value.find(Value.user_id == str(user.id)).to_list()
        value_map = {str(v.id): v for v in values}
        
        # Extract features similar to MLPredictionService
        features = []
        
        for i, activity in enumerate(activities):
            if i == 0:  # Skip first activity as we need previous context
                continue
            
            # Basic features
            feature_row = {
                'user_id': str(user.id),
                'hour': activity.date.hour,
                'day_of_week': activity.date.weekday(),
                'is_weekend': 1 if activity.date.weekday() >= 5 else 0,
                'duration': activity.duration,
                'has_notes': 1 if activity.notes else 0,
                'is_premium': 1 if user.is_premium else 0,
                'user_age_days': (activity.date - user.created_at).days
            }
            
            # Value-related features
            primary_value_id = activity.effective_value_ids[0] if activity.effective_value_ids else None
            if primary_value_id and primary_value_id in value_map:
                value = value_map[primary_value_id]
                feature_row['value_importance'] = value.importance
            else:
                feature_row['value_importance'] = 3  # Default
            
            # Historical context features
            prev_activities = activities[:i]
            
            # Time since last activity
            if prev_activities:
                last_activity = prev_activities[-1]
                time_diff = (activity.date - last_activity.date).total_seconds() / 3600
                feature_row['time_since_last_activity'] = time_diff
            else:
                feature_row['time_since_last_activity'] = 0
            
            # Weekly consistency
            week_start = activity.date - timedelta(days=7)
            recent_activities = [a for a in prev_activities if a.date >= week_start]
            feature_row['week_consistency'] = len(set(a.date.date() for a in recent_activities))
            
            # Average duration in past week
            if recent_activities:
                feature_row['avg_duration_week'] = np.mean([a.duration for a in recent_activities])
            else:
                feature_row['avg_duration_week'] = activity.duration
            
            # Calculate current streak at this point
            feature_row['current_streak'] = self._calculate_streak_at_point(prev_activities, activity.date.date())
            
            # Create target variables
            
            # 1. Habit formation success (7+ day streaks)
            feature_row['habit_success'] = 1 if feature_row['current_streak'] >= 7 else 0
            
            # 2. Streak break risk (based on future behavior)
            future_activities = activities[i+1:i+8]  # Next 7 days
            if future_activities:
                days_with_future_activity = len(set(a.date.date() for a in future_activities))
                feature_row['streak_break_risk'] = 1 if days_with_future_activity < 3 else 0
            else:
                feature_row['streak_break_risk'] = 0  # No future data available
            
            # 3. Duration target (current activity duration)
            # Already included as 'duration'
            
            features.append(feature_row)
        
        return pd.DataFrame(features)

    def _calculate_streak_at_point(self, activities: List[Activity], target_date) -> int:
        """Calculate streak length at a specific point in time"""
        if not activities:
            return 0
            
        # Get activity dates before target date
        activity_dates = sorted(set(a.date.date() for a in activities if a.date.date() <= target_date))
        
        if not activity_dates:
            return 0
        
        # Calculate streak backwards from target date
        streak = 0
        current_date = target_date
        
        for date in reversed(activity_dates):
            if date == current_date:
                streak += 1
                current_date -= timedelta(days=1)
            elif (current_date - date).days == 1:
                streak += 1
                current_date = date - timedelta(days=1)
            else:
                break
                
        return streak

    async def _train_single_model(
        self, 
        model_name: str, 
        config: Dict[str, Any], 
        training_data: pd.DataFrame
    ) -> Dict[str, Any]:
        """Train a single ML model with the given configuration"""
        
        try:
            # Prepare features and target
            required_features = config["features"]
            available_features = [f for f in required_features if f in training_data.columns]
            
            if len(available_features) < len(required_features) * 0.7:  # Need at least 70% of features
                return {"error": f"Insufficient features. Required: {required_features}, Available: {available_features}"}
            
            X = training_data[available_features].fillna(0)
            y = training_data[config["target"]]
            
            # Remove rows with missing targets
            mask = ~y.isna()
            X = X[mask]
            y = y[mask]
            
            if len(X) < 50:  # Need minimum samples
                return {"error": f"Insufficient training samples: {len(X)}"}
            
            # Choose model type
            if config["model_type"] == "classifier":
                base_model = RandomForestClassifier(random_state=42)
                scoring = 'accuracy'
            else:
                base_model = RandomForestRegressor(random_state=42)
                scoring = 'neg_mean_absolute_error'
            
            # Hyperparameter tuning (simplified for performance)
            param_grid = config["hyperparameters"]
            
            # Reduce parameter space for performance
            simplified_params = {
                'n_estimators': [50, 100],
                'max_depth': [10, None],
                'min_samples_split': [2, 5]
            }
            
            grid_search = GridSearchCV(
                base_model,
                simplified_params,
                cv=min(5, max(2, len(X) // 20)),  # Adaptive CV folds
                scoring=scoring,
                n_jobs=-1,
                verbose=0
            )
            
            # Split data
            X_train, X_test, y_train, y_test = train_test_split(
                X, y, test_size=0.2, random_state=42,
                stratify=y if config["model_type"] == "classifier" and len(np.unique(y)) > 1 else None
            )
            
            # Train model
            grid_search.fit(X_train, y_train)
            best_model = grid_search.best_estimator_
            
            # Evaluate model
            train_score = best_model.score(X_train, y_train)
            test_score = best_model.score(X_test, y_test)
            
            # Generate predictions for evaluation
            y_pred = best_model.predict(X_test)
            
            # Calculate metrics
            if config["model_type"] == "classifier":
                accuracy = accuracy_score(y_test, y_pred)
                metrics = {
                    "accuracy": accuracy,
                    "train_score": train_score,
                    "test_score": test_score
                }
            else:
                mae = mean_absolute_error(y_test, y_pred)
                metrics = {
                    "mae": mae,
                    "train_score": train_score,
                    "test_score": test_score
                }
            
            # Feature importance
            feature_importance = dict(zip(available_features, best_model.feature_importances_))
            
            # Save model
            model_path = self.models_dir / f"{model_name}_model.joblib"
            dump(best_model, model_path)
            
            # Save feature scaler if needed
            scaler = StandardScaler()
            X_scaled = scaler.fit_transform(X)
            scaler_path = self.models_dir / f"{model_name}_scaler.joblib"
            dump(scaler, scaler_path)
            
            return {
                "status": "success",
                "model_path": str(model_path),
                "scaler_path": str(scaler_path),
                "features_used": available_features,
                "training_samples": len(X_train),
                "test_samples": len(X_test),
                "best_params": grid_search.best_params_,
                "metrics": metrics,
                "feature_importance": feature_importance,
                "model_type": config["model_type"]
            }
            
        except Exception as e:
            logger.error(f"Error training {model_name}: {e}", exc_info=True)
            return {"error": f"Training failed: {str(e)}"}

    async def _save_training_metadata(self, training_results: Dict[str, Any]) -> None:
        """Save training metadata for future reference"""
        
        try:
            metadata = {
                "training_timestamp": datetime.now(timezone.utc),
                "results": training_results,
                "models_dir": str(self.models_dir)
            }
            
            metadata_path = self.models_dir / "training_metadata.pkl"
            with open(metadata_path, 'wb') as f:
                pickle.dump(metadata, f)
                
            logger.info(f"Saved training metadata to {metadata_path}")
            
        except Exception as e:
            logger.error(f"Failed to save training metadata: {e}")

    async def evaluate_models(self) -> Dict[str, Any]:
        """Evaluate existing models with fresh data"""
        
        logger.info("Starting model evaluation")
        
        try:
            # Load fresh evaluation data
            eval_data = await self._collect_evaluation_data()
            
            if eval_data.empty:
                return {"error": "No evaluation data available"}
            
            results = {}
            
            for model_name in self.model_configs.keys():
                try:
                    model_path = self.models_dir / f"{model_name}_model.joblib"
                    
                    if not model_path.exists():
                        results[model_name] = {"error": "Model not found"}
                        continue
                    
                    # Load model
                    model = load(model_path)
                    
                    # Evaluate
                    eval_result = await self._evaluate_single_model(model_name, model, eval_data)
                    results[model_name] = eval_result
                    
                except Exception as e:
                    logger.error(f"Failed to evaluate {model_name}: {e}")
                    results[model_name] = {"error": str(e)}
            
            return {
                "status": "completed",
                "evaluation_data_points": len(eval_data),
                "results": results,
                "timestamp": datetime.now(timezone.utc)
            }
            
        except Exception as e:
            logger.error(f"Error in model evaluation: {e}", exc_info=True)
            return {"error": f"Evaluation failed: {str(e)}"}

    async def _collect_evaluation_data(self) -> pd.DataFrame:
        """Collect fresh data for model evaluation"""
        
        # Get recent data not used in training
        cutoff_date = datetime.now(timezone.utc) - timedelta(days=7)  # Last week
        
        users = await User.find(
            User.last_login >= cutoff_date
        ).limit(200).to_list()  # Smaller sample for evaluation
        
        eval_data = []
        for user in users:
            try:
                user_data = await self._extract_user_training_data(user)
                if not user_data.empty:
                    eval_data.append(user_data.tail(10))  # Recent data only
            except Exception as e:
                continue
        
        if eval_data:
            return pd.concat(eval_data, ignore_index=True)
        else:
            return pd.DataFrame()

    async def _evaluate_single_model(
        self, 
        model_name: str, 
        model, 
        eval_data: pd.DataFrame
    ) -> Dict[str, Any]:
        """Evaluate a single model on fresh data"""
        
        try:
            config = self.model_configs[model_name]
            
            # Prepare features
            required_features = config["features"]
            available_features = [f for f in required_features if f in eval_data.columns]
            
            X = eval_data[available_features].fillna(0)
            y = eval_data[config["target"]]
            
            # Remove rows with missing targets
            mask = ~y.isna()
            X = X[mask]
            y = y[mask]
            
            if len(X) < 10:
                return {"error": "Insufficient evaluation samples"}
            
            # Make predictions
            y_pred = model.predict(X)
            
            # Calculate metrics
            if config["model_type"] == "classifier":
                accuracy = accuracy_score(y, y_pred)
                unique_labels = np.unique(y)
                
                return {
                    "accuracy": accuracy,
                    "samples_evaluated": len(X),
                    "class_distribution": dict(zip(*np.unique(y, return_counts=True))),
                    "prediction_distribution": dict(zip(*np.unique(y_pred, return_counts=True)))
                }
            else:
                mae = mean_absolute_error(y, y_pred)
                mse = np.mean((y - y_pred) ** 2)
                
                return {
                    "mae": mae,
                    "mse": mse,
                    "samples_evaluated": len(X),
                    "mean_actual": np.mean(y),
                    "mean_predicted": np.mean(y_pred)
                }
                
        except Exception as e:
            return {"error": f"Evaluation failed: {str(e)}"}

    async def retrain_models_if_needed(self) -> Dict[str, Any]:
        """Check if models need retraining and retrain if necessary"""
        
        try:
            # Check last training time
            metadata_path = self.models_dir / "training_metadata.pkl"
            
            should_retrain = False
            
            if not metadata_path.exists():
                should_retrain = True
                reason = "No training metadata found"
            else:
                with open(metadata_path, 'rb') as f:
                    metadata = pickle.load(f)
                
                last_training = metadata.get("training_timestamp")
                if not last_training:
                    should_retrain = True
                    reason = "No training timestamp found"
                else:
                    days_since_training = (datetime.now(timezone.utc) - last_training).days
                    if days_since_training > 7:  # Retrain weekly
                        should_retrain = True
                        reason = f"Last training was {days_since_training} days ago"
            
            if not should_retrain:
                return {
                    "status": "no_retraining_needed",
                    "reason": "Models are up to date"
                }
            
            logger.info(f"Retraining models: {reason}")
            
            # Perform retraining
            training_result = await self.train_global_models()
            
            return {
                "status": "retrained",
                "reason": reason,
                "training_result": training_result
            }
            
        except Exception as e:
            logger.error(f"Error in retraining check: {e}", exc_info=True)
            return {"error": f"Retraining check failed: {str(e)}"}

    async def get_model_info(self) -> Dict[str, Any]:
        """Get information about available models"""
        
        try:
            model_info = {}
            
            for model_name in self.model_configs.keys():
                model_path = self.models_dir / f"{model_name}_model.joblib"
                
                if model_path.exists():
                    stat = model_path.stat()
                    model_info[model_name] = {
                        "available": True,
                        "file_size_mb": round(stat.st_size / 1024 / 1024, 2),
                        "last_modified": datetime.fromtimestamp(stat.st_mtime, tz=timezone.utc),
                        "model_type": self.model_configs[model_name]["model_type"]
                    }
                else:
                    model_info[model_name] = {
                        "available": False,
                        "model_type": self.model_configs[model_name]["model_type"]
                    }
            
            # Load training metadata if available
            metadata_path = self.models_dir / "training_metadata.pkl"
            training_info = None
            
            if metadata_path.exists():
                try:
                    with open(metadata_path, 'rb') as f:
                        metadata = pickle.load(f)
                    training_info = {
                        "last_training": metadata.get("training_timestamp"),
                        "training_results": metadata.get("results", {})
                    }
                except Exception as e:
                    logger.warning(f"Failed to load training metadata: {e}")
            
            return {
                "models": model_info,
                "training_info": training_info,
                "models_directory": str(self.models_dir)
            }
            
        except Exception as e:
            logger.error(f"Error getting model info: {e}", exc_info=True)
            return {"error": f"Failed to get model info: {str(e)}"}