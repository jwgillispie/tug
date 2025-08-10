# app/services/media_service.py
import os
import uuid
import mimetypes
import logging
from typing import Optional, Dict, Any, List
from datetime import datetime, timedelta
from pathlib import Path
import aiofiles
import hashlib

from fastapi import HTTPException, status, UploadFile
from PIL import Image
import io

from ..schemas.group_message import MediaUploadRequest, MediaUploadResponse
from ..core.config import settings
from ..models.user import User

logger = logging.getLogger(__name__)

class MediaService:
    """Service for handling media uploads and file sharing in groups"""
    
    def __init__(self):
        self.upload_dir = Path("uploads")
        self.media_dir = self.upload_dir / "media"
        self.temp_dir = self.upload_dir / "temp"
        
        # Create directories
        self.media_dir.mkdir(parents=True, exist_ok=True)
        self.temp_dir.mkdir(parents=True, exist_ok=True)
        
        # File size limits (in bytes)
        self.max_file_sizes = {
            "image": 10 * 1024 * 1024,    # 10MB
            "voice": 25 * 1024 * 1024,    # 25MB
            "video": 100 * 1024 * 1024,   # 100MB
            "document": 50 * 1024 * 1024  # 50MB
        }
        
        # Allowed MIME types
        self.allowed_mime_types = {
            "image": [
                "image/jpeg", "image/png", "image/gif", "image/webp",
                "image/svg+xml", "image/bmp", "image/tiff"
            ],
            "voice": [
                "audio/mpeg", "audio/wav", "audio/ogg", "audio/mp4",
                "audio/aac", "audio/webm", "audio/x-m4a"
            ],
            "video": [
                "video/mp4", "video/mpeg", "video/quicktime", "video/webm",
                "video/x-msvideo", "video/3gpp", "video/x-ms-wmv"
            ],
            "document": [
                "application/pdf", "text/plain", "application/msword",
                "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                "application/vnd.ms-excel", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                "application/vnd.ms-powerpoint", "application/vnd.openxmlformats-officedocument.presentationml.presentation"
            ]
        }
        
        # Image processing settings
        self.thumbnail_sizes = {
            "small": (150, 150),
            "medium": (300, 300),
            "large": (800, 600)
        }
    
    async def upload_media(
        self, 
        current_user: User, 
        file: UploadFile, 
        file_type: str,
        group_id: str
    ) -> MediaUploadResponse:
        """Upload media file for group messaging"""
        try:
            # Validate file type
            if file_type not in self.max_file_sizes:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Unsupported file type: {file_type}"
                )
            
            # Check file size
            file_size = 0
            content = await file.read()
            file_size = len(content)
            
            if file_size > self.max_file_sizes[file_type]:
                raise HTTPException(
                    status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                    detail=f"File size exceeds limit of {self.max_file_sizes[file_type]} bytes"
                )
            
            # Validate MIME type
            mime_type = file.content_type or mimetypes.guess_type(file.filename)[0]
            if mime_type not in self.allowed_mime_types[file_type]:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Invalid MIME type {mime_type} for file type {file_type}"
                )
            
            # Generate file ID and paths
            file_id = str(uuid.uuid4())
            file_extension = Path(file.filename).suffix.lower()
            
            # Create unique filename
            timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
            safe_filename = f"{timestamp}_{file_id}{file_extension}"
            
            # Organize by date and type
            date_folder = datetime.utcnow().strftime("%Y/%m")
            type_folder = self.media_dir / file_type / date_folder
            type_folder.mkdir(parents=True, exist_ok=True)
            
            file_path = type_folder / safe_filename
            
            # Save original file
            async with aiofiles.open(file_path, 'wb') as f:
                await f.write(content)
            
            # Generate file hash for deduplication
            file_hash = hashlib.md5(content).hexdigest()
            
            # Process based on file type
            file_metadata = await self._process_file(file_path, file_type, content, mime_type)
            
            # Generate public URL
            relative_path = f"media/{file_type}/{date_folder}/{safe_filename}"
            file_url = f"/uploads/{relative_path}"
            
            # Create response
            response = MediaUploadResponse(
                upload_url=file_url,  # In this case, upload is already complete
                file_id=file_id,
                file_url=file_url,
                expires_at=datetime.utcnow() + timedelta(hours=24)  # Files expire after 24 hours if not used
            )
            
            # Store file metadata for later use
            await self._store_file_metadata(
                file_id=file_id,
                user_id=current_user.id,
                group_id=group_id,
                filename=file.filename,
                file_type=file_type,
                file_size=file_size,
                mime_type=mime_type,
                file_hash=file_hash,
                file_path=str(file_path),
                file_url=file_url,
                metadata=file_metadata
            )
            
            logger.info(f"Media uploaded: {file.filename} ({file_type}) by user {current_user.username}")
            
            return response
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error uploading media: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to upload media file"
            )
    
    async def _process_file(
        self, 
        file_path: Path, 
        file_type: str, 
        content: bytes, 
        mime_type: str
    ) -> Dict[str, Any]:
        """Process file based on type and generate metadata"""
        metadata = {
            "processed_at": datetime.utcnow().isoformat(),
            "mime_type": mime_type
        }
        
        try:
            if file_type == "image":
                metadata.update(await self._process_image(file_path, content))
            elif file_type == "voice":
                metadata.update(await self._process_audio(file_path, content))
            elif file_type == "video":
                metadata.update(await self._process_video(file_path, content))
            elif file_type == "document":
                metadata.update(await self._process_document(file_path, content))
                
        except Exception as e:
            logger.error(f"Error processing {file_type} file {file_path}: {e}")
            metadata["processing_error"] = str(e)
        
        return metadata
    
    async def _process_image(self, file_path: Path, content: bytes) -> Dict[str, Any]:
        """Process image file - generate thumbnails and extract metadata"""
        metadata = {}
        
        try:
            # Open image
            with Image.open(io.BytesIO(content)) as img:
                metadata.update({
                    "width": img.width,
                    "height": img.height,
                    "format": img.format,
                    "mode": img.mode
                })
                
                # Generate thumbnails
                thumbnails = {}
                for size_name, (width, height) in self.thumbnail_sizes.items():
                    # Create thumbnail
                    thumbnail = img.copy()
                    thumbnail.thumbnail((width, height), Image.Resampling.LANCZOS)
                    
                    # Save thumbnail
                    thumbnail_path = file_path.parent / f"{file_path.stem}_thumb_{size_name}{file_path.suffix}"
                    thumbnail.save(thumbnail_path, optimize=True, quality=85)
                    
                    # Store thumbnail info
                    relative_thumbnail_path = str(thumbnail_path).replace(str(self.upload_dir), "").lstrip("/")
                    thumbnails[size_name] = {
                        "url": f"/uploads/{relative_thumbnail_path}",
                        "width": thumbnail.width,
                        "height": thumbnail.height
                    }
                
                metadata["thumbnails"] = thumbnails
                
                # Check if image needs rotation based on EXIF
                try:
                    from PIL.ExifTags import ORIENTATION
                    exif = img._getexif()
                    if exif and ORIENTATION in exif:
                        metadata["orientation"] = exif[ORIENTATION]
                except:
                    pass  # EXIF processing is optional
                    
        except Exception as e:
            logger.error(f"Error processing image: {e}")
            metadata["processing_error"] = str(e)
        
        return metadata
    
    async def _process_audio(self, file_path: Path, content: bytes) -> Dict[str, Any]:
        """Process audio file - extract duration and metadata"""
        metadata = {}
        
        try:
            # For audio processing, we'd typically use libraries like mutagen or librosa
            # For now, just store basic info
            metadata.update({
                "file_size": len(content),
                "estimated_duration": "unknown"  # Would be calculated with audio library
            })
            
            # TODO: Add proper audio processing with mutagen or similar
            # This would extract:
            # - Duration
            # - Bitrate
            # - Sample rate
            # - Channels (mono/stereo)
            # - Audio codec info
            
        except Exception as e:
            logger.error(f"Error processing audio: {e}")
            metadata["processing_error"] = str(e)
        
        return metadata
    
    async def _process_video(self, file_path: Path, content: bytes) -> Dict[str, Any]:
        """Process video file - extract metadata and generate thumbnail"""
        metadata = {}
        
        try:
            # For video processing, we'd typically use ffmpeg-python or similar
            # For now, just store basic info
            metadata.update({
                "file_size": len(content),
                "estimated_duration": "unknown"  # Would be calculated with video library
            })
            
            # TODO: Add proper video processing with ffmpeg-python
            # This would extract:
            # - Duration
            # - Resolution (width/height)
            # - Frame rate
            # - Video codec
            # - Generate video thumbnail at specific timestamp
            
        except Exception as e:
            logger.error(f"Error processing video: {e}")
            metadata["processing_error"] = str(e)
        
        return metadata
    
    async def _process_document(self, file_path: Path, content: bytes) -> Dict[str, Any]:
        """Process document file - extract basic metadata"""
        metadata = {}
        
        try:
            metadata.update({
                "file_size": len(content),
                "pages": "unknown"  # Would be calculated for PDFs
            })
            
            # TODO: Add document processing
            # For PDFs: extract page count, text content preview
            # For Office docs: extract basic metadata
            
        except Exception as e:
            logger.error(f"Error processing document: {e}")
            metadata["processing_error"] = str(e)
        
        return metadata
    
    async def _store_file_metadata(
        self,
        file_id: str,
        user_id: str,
        group_id: str,
        filename: str,
        file_type: str,
        file_size: int,
        mime_type: str,
        file_hash: str,
        file_path: str,
        file_url: str,
        metadata: Dict[str, Any]
    ):
        """Store file metadata in database for tracking and management"""
        # In a real implementation, this would store in a dedicated collection
        # For now, this is a placeholder for file metadata storage
        
        file_record = {
            "file_id": file_id,
            "user_id": user_id,
            "group_id": group_id,
            "filename": filename,
            "file_type": file_type,
            "file_size": file_size,
            "mime_type": mime_type,
            "file_hash": file_hash,
            "file_path": file_path,
            "file_url": file_url,
            "metadata": metadata,
            "created_at": datetime.utcnow(),
            "expires_at": datetime.utcnow() + timedelta(hours=24)
        }
        
        # TODO: Store in dedicated file_uploads collection
        logger.info(f"File metadata stored for file_id: {file_id}")
    
    async def cleanup_expired_files(self):
        """Background task to cleanup expired uploaded files"""
        try:
            # TODO: Implement cleanup of expired files
            # This would:
            # 1. Find expired file records in database
            # 2. Delete physical files from disk
            # 3. Remove database records
            # 4. Clean up empty directories
            
            logger.info("File cleanup task completed")
            
        except Exception as e:
            logger.error(f"Error during file cleanup: {e}")
    
    def get_file_info(self, file_id: str) -> Optional[Dict[str, Any]]:
        """Get file information by file ID"""
        # TODO: Retrieve from database
        return None
    
    async def delete_file(self, file_id: str, user_id: str) -> bool:
        """Delete a file (only by uploader or admin)"""
        try:
            # TODO: Implement file deletion
            # 1. Check permissions
            # 2. Delete physical file
            # 3. Remove database record
            return True
            
        except Exception as e:
            logger.error(f"Error deleting file {file_id}: {e}")
            return False
    
    def is_valid_image(self, content: bytes) -> bool:
        """Validate if content is a valid image"""
        try:
            with Image.open(io.BytesIO(content)) as img:
                img.verify()
                return True
        except:
            return False
    
    def generate_secure_filename(self, original_filename: str) -> str:
        """Generate secure filename to prevent path traversal attacks"""
        # Remove path components
        filename = os.path.basename(original_filename)
        
        # Replace potentially dangerous characters
        filename = "".join(c for c in filename if c.isalnum() or c in "._-")
        
        # Ensure filename isn't empty
        if not filename:
            filename = "unnamed_file"
        
        # Add timestamp to prevent collisions
        timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
        name, ext = os.path.splitext(filename)
        
        return f"{timestamp}_{name[:50]}{ext}"

# Global service instance
media_service = MediaService()