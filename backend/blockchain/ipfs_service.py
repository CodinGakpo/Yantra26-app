"""
Local File Storage Service for Evidence (Replaces IPFS)

Why Local Storage?
- Simple and reliable for storing uploaded evidence files
- No external dependencies (Infura, Web3.Storage, etc.)
- Files saved locally under configured directory
- SHA-256 hash still anchored on blockchain for integrity
- Works seamlessly with Django's MEDIA_ROOT

How it works:
1. Files are saved to a configured local directory (e.g., MEDIA_ROOT/uploads/)
2. SHA-256 hash is computed for blockchain anchoring
3. File path + hash + transaction hash stored in MySQL
4. Files served via Django MEDIA_URL
"""

import logging
import os
import hashlib
import uuid
from pathlib import Path
from typing import Tuple, Optional
from datetime import datetime

from django.conf import settings

logger = logging.getLogger(__name__)


class LocalFileStorageService:
    """
    Service for storing and retrieving evidence files locally.
    
    Replaces IPFS with local file storage while maintaining blockchain anchoring.
    """
    
    def __init__(self):
        """Initialize local file storage service"""
        self.upload_dir = self._get_upload_directory()
        self._ensure_directory_exists()
    
    def _get_upload_directory(self) -> Path:
        """Get the configured upload directory"""
        # Use LOCAL_FILE_UPLOAD_DIR from settings or default to MEDIA_ROOT/uploads
        if hasattr(settings, 'LOCAL_FILE_UPLOAD_DIR'):
            upload_dir = Path(settings.LOCAL_FILE_UPLOAD_DIR)
        else:
            # Fallback to MEDIA_ROOT/uploads
            media_root = getattr(settings, 'MEDIA_ROOT', Path(settings.BASE_DIR) / 'media')
            upload_dir = Path(media_root) / 'uploads'
        
        return upload_dir
    
    def _ensure_directory_exists(self):
        """Create upload directory if it doesn't exist"""
        try:
            self.upload_dir.mkdir(parents=True, exist_ok=True)
            logger.info(f"Upload directory ready: {self.upload_dir}")
        except Exception as e:
            logger.error(f"Failed to create upload directory: {e}")
            raise
    
    def upload_file(
        self,
        file_content: bytes,
        file_name: str,
        complaint_id: str = None
    ) -> Tuple[Optional[str], Optional[str]]:
        """
        Save file to local storage.
        
        Args:
            file_content: Raw file bytes
            file_name: Original filename
            complaint_id: Optional complaint ID for organizing files
            
        Returns:
            (file_path, file_url) or (None, None) if failed
            - file_path: Relative path from MEDIA_ROOT (saved to DB)
            - file_url: Full URL for serving the file
        """
        try:
            # Generate unique filename to avoid collisions
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            unique_id = uuid.uuid4().hex[:8]
            file_extension = os.path.splitext(file_name)[1]
            safe_name = f"{timestamp}_{unique_id}{file_extension}"
            
            # Organize by complaint_id if provided
            if complaint_id:
                complaint_dir = self.upload_dir / complaint_id
                complaint_dir.mkdir(parents=True, exist_ok=True)
                file_full_path = complaint_dir / safe_name
                # Relative path for DB storage
                file_relative_path = f"uploads/{complaint_id}/{safe_name}"
            else:
                file_full_path = self.upload_dir / safe_name
                file_relative_path = f"uploads/{safe_name}"
            
            # Write file to disk
            with open(file_full_path, 'wb') as f:
                f.write(file_content)
            
            logger.info(f"File saved locally: {file_full_path}")
            
            # Generate file URL using Django's MEDIA_URL
            media_url = getattr(settings, 'MEDIA_URL', '/media/')
            file_url = f"{media_url}{file_relative_path}"
            
            return file_relative_path, file_url
            
        except Exception as e:
            logger.error(f"Local file upload error: {e}")
            return None, None
    
    def retrieve_file(self, file_path: str) -> Optional[bytes]:
        """
        Retrieve file from local storage.
        
        Args:
            file_path: Relative file path (from DB)
            
        Returns:
            File content as bytes or None if failed
        """
        try:
            # Construct full path
            if file_path.startswith('uploads/'):
                # Remove 'uploads/' prefix since it's already in upload_dir
                relative_path = file_path[8:]
                full_path = self.upload_dir / relative_path
            else:
                full_path = self.upload_dir / file_path
            
            if not full_path.exists():
                logger.error(f"File not found: {full_path}")
                return None
            
            with open(full_path, 'rb') as f:
                content = f.read()
            
            logger.info(f"File retrieved: {full_path}")
            return content
            
        except Exception as e:
            logger.error(f"File retrieval error: {e}")
            return None
    
    def get_file_url(self, file_path: str) -> str:
        """
        Get public URL for a file.
        
        Args:
            file_path: Relative file path (from DB)
            
        Returns:
            Public URL for serving the file
        """
        media_url = getattr(settings, 'MEDIA_URL', '/media/')
        return f"{media_url}{file_path}"
    
    def verify_file_exists(self, file_path: str) -> bool:
        """
        Check if file exists on local storage.
        
        Args:
            file_path: Relative file path (from DB)
            
        Returns:
            True if file exists
        """
        try:
            if file_path.startswith('uploads/'):
                relative_path = file_path[8:]
                full_path = self.upload_dir / relative_path
            else:
                full_path = self.upload_dir / file_path
            
            return full_path.exists()
            
        except Exception as e:
            logger.error(f"File existence check failed: {e}")
            return False
    
    def delete_file(self, file_path: str) -> bool:
        """
        Delete file from local storage.
        
        Args:
            file_path: Relative file path (from DB)
            
        Returns:
            True if deleted successfully
        """
        try:
            if file_path.startswith('uploads/'):
                relative_path = file_path[8:]
                full_path = self.upload_dir / relative_path
            else:
                full_path = self.upload_dir / file_path
            
            if full_path.exists():
                full_path.unlink()
                logger.info(f"File deleted: {full_path}")
                return True
            else:
                logger.warning(f"File not found for deletion: {full_path}")
                return False
                
        except Exception as e:
            logger.error(f"File deletion error: {e}")
            return False
    
    def compute_file_hash(self, file_content: bytes) -> str:
        """
        Compute SHA-256 hash of file content.
        
        Args:
            file_content: Raw file bytes
            
        Returns:
            SHA-256 hash (hex string)
        """
        return hashlib.sha256(file_content).hexdigest()


# Singleton instance
_local_storage_service = None


def get_local_storage_service() -> LocalFileStorageService:
    """Get singleton local storage service instance"""
    global _local_storage_service
    
    if _local_storage_service is None:
        _local_storage_service = LocalFileStorageService()
    
    return _local_storage_service


# Backward compatibility alias (can be used in place of get_ipfs_service)
def get_file_storage_service() -> LocalFileStorageService:
    """Alias for get_local_storage_service for backward compatibility"""
    return get_local_storage_service()
