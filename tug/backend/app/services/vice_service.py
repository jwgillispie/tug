# app/services/vice_service.py
from datetime import datetime, date, timedelta
from typing import List, Optional
from bson import ObjectId
from fastapi import HTTPException, status
import logging

from ..models.user import User
from ..models.vice import Vice
from ..models.indulgence import Indulgence
from ..schemas.vice import ViceCreate, ViceUpdate
from ..schemas.indulgence import IndulgenceCreate

logger = logging.getLogger(__name__)

class ViceService:
    """Service for handling vice-related operations"""

    @staticmethod
    async def create_vice(user: User, vice_data: ViceCreate) -> Vice:
        """Create a new vice for a user"""
        # Check if user has less than 10 active vices (reasonable limit)
        active_vices_count = await Vice.find(
            Vice.user_id == str(user.id),
            Vice.active == True
        ).count()
        
        if active_vices_count >= 10:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Maximum 10 active vices allowed"
            )
        
        # Create new vice
        new_vice = Vice(
            user_id=str(user.id),
            name=vice_data.name,
            severity=vice_data.severity,
            description=vice_data.description,
            color=vice_data.color
        )
        
        await new_vice.insert()
        return new_vice

    @staticmethod
    async def get_vices(user: User, include_inactive: bool = False) -> List[Vice]:
        """Get all vices for a user"""
        query = {Vice.user_id: str(user.id)}
        
        if not include_inactive:
            query[Vice.active] = True
        
        vices = await Vice.find(query).sort(-Vice.created_at).to_list()
        
        # Update current streaks based on calculation and check for milestones
        for vice in vices:
            calculated_streak = vice.calculate_current_streak()
            if calculated_streak != vice.current_streak:
                old_streak = vice.current_streak
                vice.current_streak = calculated_streak
                
                # Check if a milestone was reached
                milestone = vice.check_milestone_reached(old_streak, calculated_streak)
                if milestone:
                    await vice.record_milestone_achievement(milestone)
                    # Import here to avoid circular imports
                    from .social_service import SocialService
                    await SocialService.create_vice_milestone_post(user, vice, milestone)
                
                await vice.save()
        
        return vices

    @staticmethod
    async def get_vice(user: User, vice_id: str) -> Vice:
        """Get a specific vice by ID"""
        try:
            object_id = ObjectId(vice_id)
        except Exception:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid vice ID format"
            )
        
        vice = await Vice.find_one(
            Vice.id == object_id,
            Vice.user_id == str(user.id)
        )
        
        if not vice:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Vice not found"
            )
        
        # Update current streak based on calculation
        calculated_streak = vice.calculate_current_streak()
        if calculated_streak != vice.current_streak:
            vice.current_streak = calculated_streak
            await vice.save()
        
        return vice

    @staticmethod
    async def update_vice(user: User, vice_id: str, vice_update: ViceUpdate) -> Vice:
        """Update a vice"""
        vice = await ViceService.get_vice(user, vice_id)
        
        # Update fields that were provided
        update_data = vice_update.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(vice, field, value)
        
        vice.updated_at = datetime.utcnow()
        await vice.save()
        
        return vice

    @staticmethod
    async def delete_vice(user: User, vice_id: str) -> None:
        """Delete a vice and all its indulgences"""
        vice = await ViceService.get_vice(user, vice_id)
        
        # Delete all indulgences associated with this vice
        await Indulgence.find(
            Indulgence.vice_id == vice_id,
            Indulgence.user_id == str(user.id)
        ).delete()
        
        # Delete the vice
        await vice.delete()

    @staticmethod
    async def record_indulgence(user: User, indulgence_data: IndulgenceCreate) -> Indulgence:
        """Record a new indulgence for a vice"""
        # Verify the vice exists and belongs to the user
        vice = await ViceService.get_vice(user, indulgence_data.vice_id)
        
        # Create the indulgence
        new_indulgence = Indulgence(
            vice_id=indulgence_data.vice_id,
            user_id=str(user.id),
            date=indulgence_data.date,
            duration=indulgence_data.duration,
            notes=indulgence_data.notes,
            severity_at_time=indulgence_data.severity_at_time,
            triggers=indulgence_data.triggers,
            emotional_state=indulgence_data.emotional_state,
            is_public=indulgence_data.is_public,
            notes_public=indulgence_data.notes_public
        )
        
        await new_indulgence.insert()
        
        # Update the vice's streak information
        await vice.update_streak_on_indulgence()
        
        # Create social post if indulgence is public and has user-provided notes
        if indulgence_data.is_public and indulgence_data.notes_public and indulgence_data.notes:
            await ViceService._create_indulgence_social_post(user, new_indulgence, vice)
        
        return new_indulgence

    @staticmethod
    async def record_multi_vice_indulgence(user: User, indulgence_data: IndulgenceCreate) -> Indulgence:
        """Record a new indulgence for multiple vices"""
        # Verify all vices exist and belong to the user
        vices = []
        for vice_id in indulgence_data.vice_ids:
            vice = await ViceService.get_vice(user, vice_id)
            vices.append(vice)
        
        # Create the indulgence with multiple vices
        new_indulgence = Indulgence(
            vice_ids=indulgence_data.vice_ids,
            user_id=str(user.id),
            date=indulgence_data.date,
            duration=indulgence_data.duration,
            notes=indulgence_data.notes,
            severity_at_time=indulgence_data.severity_at_time,
            triggers=indulgence_data.triggers,
            emotional_state=indulgence_data.emotional_state,
            is_public=indulgence_data.is_public,
            notes_public=indulgence_data.notes_public
        )
        
        await new_indulgence.insert()
        
        # Update all associated vices' streak information
        await new_indulgence.update_vice_streaks()
        
        # Create social post if indulgence is public and has user-provided notes
        # Use the primary (first) vice for social post
        if indulgence_data.is_public and indulgence_data.notes_public and indulgence_data.notes and vices:
            await ViceService._create_indulgence_social_post(user, new_indulgence, vices[0])
        
        return new_indulgence

    @staticmethod
    async def vice_belongs_to_user(user: User, vice_id: str) -> bool:
        """Check if a vice belongs to the current user"""
        try:
            await ViceService.get_vice(user, vice_id)
            return True
        except HTTPException:
            return False

    @staticmethod
    async def get_all_user_indulgences(user: User, limit: Optional[int] = None) -> List[Indulgence]:
        """Get all indulgences for a user across all vices"""
        query = Indulgence.find(
            Indulgence.user_id == str(user.id)
        ).sort(-Indulgence.date)
        
        if limit:
            query = query.limit(limit)
        
        return await query.to_list()

    @staticmethod
    async def get_indulgence_by_id(user: User, indulgence_id: str) -> Indulgence:
        """Get a specific indulgence by ID"""
        try:
            indulgence = await Indulgence.get(indulgence_id)
            if not indulgence or indulgence.user_id != str(user.id):
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Indulgence not found"
                )
            return indulgence
        except Exception as e:
            if isinstance(e, HTTPException):
                raise
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Indulgence not found"
            )

    @staticmethod
    async def update_indulgence(user: User, indulgence_id: str, update_data) -> Indulgence:
        """Update an existing indulgence"""
        indulgence = await ViceService.get_indulgence_by_id(user, indulgence_id)
        
        # Update fields
        update_dict = update_data.dict(exclude_unset=True)
        for field, value in update_dict.items():
            setattr(indulgence, field, value)
        
        indulgence.updated_at = datetime.utcnow()
        await indulgence.save()
        
        return indulgence

    @staticmethod
    async def delete_indulgence(user: User, indulgence_id: str) -> None:
        """Delete an indulgence"""
        indulgence = await ViceService.get_indulgence_by_id(user, indulgence_id)
        await indulgence.delete()

    @staticmethod
    async def get_indulgences(user: User, vice_id: str, limit: Optional[int] = None) -> List[Indulgence]:
        """Get indulgences for a specific vice"""
        # Verify the vice exists and belongs to the user
        await ViceService.get_vice(user, vice_id)
        
        # Updated to handle both old single-vice indulgences and new multi-vice indulgences
        query = Indulgence.find(
            {"vice_ids": {"$in": [vice_id]}},  # Check if vice_id is in the vice_ids array
            Indulgence.user_id == str(user.id)
        ).sort(-Indulgence.date)
        
        if limit:
            query = query.limit(limit)
        
        return await query.to_list()

    @staticmethod
    async def update_vice_streak(user: User, vice_id: str, new_streak: int) -> Vice:
        """Manually update a vice's current streak"""
        vice = await ViceService.get_vice(user, vice_id)
        old_streak = vice.current_streak
        await vice.update_clean_streak(new_streak)
        
        # Check if a milestone was reached during manual update
        milestone = vice.check_milestone_reached(old_streak, new_streak)
        if milestone:
            from .social_service import SocialService
            await SocialService.create_vice_milestone_post(user, vice, milestone)
        
        return vice

    @staticmethod
    async def mark_clean_day(user: User, vice_id: str, clean_date: datetime) -> Vice:
        """Mark a specific day as clean for a vice"""
        vice = await ViceService.get_vice(user, vice_id)
        
        # For now, we'll just increment the current streak
        # In a more sophisticated system, you might track individual clean days
        old_streak = vice.current_streak
        vice.current_streak += 1
        if vice.current_streak > vice.longest_streak:
            vice.longest_streak = vice.current_streak
        
        # Check if a milestone was reached
        milestone = vice.check_milestone_reached(old_streak, vice.current_streak)
        if milestone:
            await vice.record_milestone_achievement(milestone)
            from .social_service import SocialService
            await SocialService.create_vice_milestone_post(user, vice, milestone)
        
        vice.updated_at = datetime.utcnow()
        await vice.save()
        
        return vice

    @staticmethod
    async def get_vice_stats(user: User, vice_id: Optional[str] = None) -> dict:
        """Get statistics for vices"""
        if vice_id:
            # Stats for a specific vice
            vice = await ViceService.get_vice(user, vice_id)
            indulgences = await ViceService.get_indulgences(user, vice_id)
            
            return {
                "vice_id": vice_id,
                "name": vice.name,
                "current_streak": vice.current_streak,
                "longest_streak": vice.longest_streak,
                "total_indulgences": vice.total_indulgences,
                "last_indulgence_date": vice.last_indulgence_date,
                "recent_indulgences": len([i for i in indulgences if i.date > datetime.utcnow() - timedelta(days=30)])
            }
        else:
            # Overall stats for all vices
            vices = await ViceService.get_vices(user)
            total_vices = len(vices)
            active_vices = len([v for v in vices if v.active])
            total_indulgences = sum(v.total_indulgences for v in vices)
            average_streak = sum(v.current_streak for v in vices) / total_vices if total_vices > 0 else 0
            
            return {
                "total_vices": total_vices,
                "active_vices": active_vices,
                "total_indulgences": total_indulgences,
                "average_current_streak": round(average_streak, 1),
                "longest_streak_overall": max((v.longest_streak for v in vices), default=0)
            }
    
    @staticmethod
    async def _create_indulgence_social_post(user: User, indulgence: Indulgence, vice: Vice) -> None:
        """Create a social post for a public indulgence with user-provided content"""
        try:
            # Only use user-provided notes as the content
            content = indulgence.notes
            
            # Create the social post with user's own words
            # Import here to avoid circular imports
            from ..models.social_post import SocialPost, PostType
            
            social_post = SocialPost(
                user_id=str(user.id),
                content=content,
                post_type=PostType.VICE_INDULGENCE,
                vice_id=str(vice.id),
                is_public=True
            )
            
            await social_post.save()
            logger.info(f"Created social post for indulgence {indulgence.id} by user {user.id}")
            
        except Exception as e:
            logger.error(f"Failed to create social post for indulgence {indulgence.id}: {e}")
            # Don't raise exception to avoid breaking indulgence creation