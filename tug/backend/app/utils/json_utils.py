# app/utils/json_utils.py
from bson import ObjectId
from typing import Any, Dict, List, Union
from datetime import datetime

class MongoJSONEncoder:
    @staticmethod
    def encode_mongo_data(obj: Any) -> Any:
        """Recursively convert MongoDB types to JSON-serializable types."""
        if isinstance(obj, ObjectId):
            return str(obj)
        elif isinstance(obj, datetime):
            return obj.isoformat()
        elif isinstance(obj, dict):
            return {k: MongoJSONEncoder.encode_mongo_data(v) for k, v in obj.items()}
        elif isinstance(obj, list):
            return [MongoJSONEncoder.encode_mongo_data(item) for item in obj]
        elif hasattr(obj, "dict") and callable(getattr(obj, "dict")):
            # Handle Pydantic models or other objects with a dict() method
            return MongoJSONEncoder.encode_mongo_data(obj.dict())
        return obj

    @staticmethod
    def jsonify(data: Any) -> Any:
        """Convert data to JSON-compatible format."""
        return MongoJSONEncoder.encode_mongo_data(data)