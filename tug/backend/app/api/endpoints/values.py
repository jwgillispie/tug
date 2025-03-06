# app/api/endpoints/values.py
from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from datetime import datetime
from ...models.user import User
from ...models.value import Value
from ...schemas.value import ValueCreate, ValueUpdate, ValueResponse
from ...core.auth import get_current_user

router = APIRouter()

@router.post("/", response_model=ValueResponse, status_code=status.HTTP_201_CREATED)
async def create_value(
    value: ValueCreate,
    current_user: User = Depends(get_current_user)
):
    """Create a new value for the current user"""
    # Check if user has less than 5 active values
    active_values_count = await Value.find(
        Value.user_id == str(current_user.id),
        Value.active == True
    ).count()
    
    if active_values_count >= 5:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Maximum 5 active values allowed"
        )
    
    # Create new value
    new_value = Value(
        user_id=str(current_user.id),
        name=value.name,
        importance=value.importance,
        description=value.description,
        color=value.color
    )
    
    await new_value.insert()
    return new_value

@router.get("/", response_model=List[ValueResponse])
async def get_values(
    current_user: User = Depends(get_current_user),
    include_inactive: bool = False
):
    """Get all values for the current user"""
    query = {Value.user_id: str(current_user.id)}
    
    if not include_inactive:
        query[Value.active] = True
    
    values = await Value.find(
        query
    ).sort(-Value.importance).to_list()
    
    return values

@router.get("/{value_id}", response_model=ValueResponse)
async def get_value(
    value_id: str,
    current_user: User = Depends(get_current_user)
):
    """Get a specific value by ID"""
    value = await Value.find_one(
        Value.id == value_id,
        Value.user_id == str(current_user.id)
    )
    
    if not value:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Value not found"
        )
    
    return value

@router.patch("/{value_id}", response_model=ValueResponse)
async def update_value(
    value_id: str,
    value_update: ValueUpdate,
    current_user: User = Depends(get_current_user)
):
    """Update a specific value"""
    value = await Value.find_one(
        Value.id == value_id,
        Value.user_id == str(current_user.id)
    )
    
    if not value:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Value not found"
        )
    
    # Update value with provided data
    update_data = value_update.model_dump(exclude_unset=True)
    
    if update_data:
        for field, value_data in update_data.items():
            setattr(value, field, value_data)
        
        value.updated_at = datetime.utcnow()
        await value.save()
    
    return value

@router.delete("/{value_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_value(
    value_id: str,
    current_user: User = Depends(get_current_user)
):
    """Delete (deactivate) a value"""
    value = await Value.find_one(
        Value.id == value_id,
        Value.user_id == str(current_user.id)
    )
    
    if not value:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Value not found"
        )
    
    # Soft delete (deactivate)
    value.active = False
    value.updated_at = datetime.utcnow()
    await value.save()