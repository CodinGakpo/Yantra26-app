# Blockchain Evidence Storage Refactor Guide

## Overview
This guide documents the complete refactoring of the blockchain/evidence backend integration to remove IPFS and use local file storage instead.

## Changes Made

### 1. File Storage Service (`blockchain/ipfs_service.py`)
**Before:** Used IPFS (Infura) for file storage  
**After:** Local file storage with SHA-256 hash anchoring on blockchain

**Key Changes:**
- Removed all Infura/Web3.Storage API calls
- Implemented `LocalFileStorageService` class for local file operations
- Files saved to `MEDIA_ROOT/uploads/` organized by complaint ID
- Maintained SHA-256 hash computation for blockchain anchoring
- Added methods: `upload_file()`, `retrieve_file()`, `get_file_url()`, `verify_file_exists()`, `delete_file()`

### 2. Database Models (`blockchain/models.py`)
**Changes to `EvidenceHash` model:**
- ✅ Changed `ipfs_cid` field to `file_path` (stores relative path from MEDIA_ROOT)
- ✅ Updated indexes: `ipfs_cid` → `file_path`
- ✅ Kept SHA-256 `file_hash` for blockchain anchoring
- ✅ Kept `tx_hash`, `block_timestamp`, and metadata fields

### 3. Views (`blockchain/views.py`)
**Updated functions:**
- `upload_evidence_with_blockchain()`: Uses local storage instead of IPFS
- `get_blockchain_status()`: Returns local file URLs instead of IPFS gateway URLs
- Response now includes `file_path` and `file_url` instead of `ipfs_cid` and `ipfs_url`

### 4. Signals (`blockchain/signals.py`)
**Updated:**
- `log_evidence_uploaded()`: Changed parameters from `ipfs_cid` to `file_path`
- Passes local file path to Celery tasks

### 5. Celery Tasks (`blockchain/tasks.py`)
**Updated:**
- `anchor_evidence_async()`: Changed parameter from `ipfs_cid` to `file_path`
- Keeps blockchain anchoring logic unchanged
- Error handling and retry logic preserved

### 6. Blockchain Service (`blockchain/services.py`)
**Updated methods:**
- `anchor_evidence()`: Changed parameter from `ipfs_cid` to `file_path`
- `verify_evidence_integrity()`: Returns `file_path` instead of `ipfs_cid`
- Smart contract interaction remains unchanged

### 7. Configuration Files

#### `.env` Changes
**Removed:**
```bash
IPFS_API_URL=https://ipfs.infura.io:5001
IPFS_GATEWAY_URL=https://ipfs.io
IPFS_PROJECT_ID=YOUR_INFURA_PROJECT_ID
IPFS_PROJECT_SECRET="..."
```

**Added:**
```bash
LOCAL_FILE_UPLOAD_DIR="media/uploads"
```

#### `blockchain_settings.py` Changes
**Removed IPFS configuration section**  
**Added:**
```python
LOCAL_FILE_UPLOAD_DIR = os.getenv('LOCAL_FILE_UPLOAD_DIR', os.path.join(BASE_DIR, 'media/uploads'))
MEDIA_ROOT = os.getenv('MEDIA_ROOT', os.path.join(BASE_DIR, 'media'))
MEDIA_URL = os.getenv('MEDIA_URL', '/media/')
```

#### `report_hub/settings/base.py` Changes
**Added:**
```python
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / "media"
```

## Database Migration Required

You need to create and run a Django migration to update the `EvidenceHash` model in MySQL.

### Step 1: Create Migration
```bash
cd /Users/avi19/Documents/projects/hackathons/devsoc26/backend
python manage.py makemigrations blockchain --name change_ipfs_cid_to_file_path
```

### Step 2: Review Migration
The migration should:
1. Rename field `ipfs_cid` to `file_path`
2. Change max_length from 100 to 500
3. Update help text
4. Update index from `ipfs_cid` to `file_path`

### Step 3: Handle Existing Data (If Any)
If you have existing evidence records in the database:

**Option A: Fresh Start (Recommended if no production data)**
```bash
# Delete existing evidence records
python manage.py shell
>>> from blockchain.models import EvidenceHash
>>> EvidenceHash.objects.all().delete()
>>> exit()
```

**Option B: Data Migration (If you have production data)**
Create a data migration to convert existing IPFS CIDs:
```bash
python manage.py makemigrations blockchain --empty --name migrate_ipfs_to_local
```

Edit the migration file to add data transformation logic (mark old records as needing re-upload).

### Step 4: Run Migration
```bash
python manage.py migrate blockchain
```

### Step 5: Verify Migration
```bash
python manage.py shell
>>> from blockchain.models import EvidenceHash
>>> EvidenceHash._meta.get_field('file_path')
>>> # Should show CharField with max_length=500
```

## Directory Setup

### Create Upload Directory
```bash
cd /Users/avi19/Documents/projects/hackathons/devsoc26/backend
mkdir -p media/uploads
chmod 755 media/uploads
```

### Add to .gitignore
Add this to your `.gitignore`:
```
# Media files (uploaded evidence)
media/
!media/.gitkeep
```

Create placeholder:
```bash
touch media/.gitkeep
```

## URL Configuration

### Add Media URL Serving (Development)
In `report_hub/urls.py`, add:
```python
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    # ... your existing URL patterns
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
```

### Production Setup
For production, configure your web server (nginx/Apache) to serve media files:

**Nginx Example:**
```nginx
location /media/ {
    alias /path/to/backend/media/;
    expires 30d;
    add_header Cache-Control "public, immutable";
}
```

## Testing the Changes

### 1. Test File Upload
```python
# In Django shell or test
from blockchain.ipfs_service import get_local_storage_service

storage = get_local_storage_service()
test_content = b"test file content"
file_path, file_url = storage.upload_file(
    test_content, 
    "test.txt", 
    complaint_id="TEST123"
)
print(f"File saved to: {file_path}")
print(f"File URL: {file_url}")
```

### 2. Test Hash Computation
```python
file_hash = storage.compute_file_hash(test_content)
print(f"SHA-256 hash: {file_hash}")
```

### 3. Test File Retrieval
```python
retrieved = storage.retrieve_file(file_path)
print(f"Retrieved: {retrieved == test_content}")
```

### 4. Test Complete Upload Flow
```bash
# Use curl or Postman to test the API endpoint
curl -X POST http://localhost:8000/api/reports/ABC123/evidence/ \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@/path/to/test-file.pdf"
```

Expected response:
```json
{
  "file_path": "uploads/ABC123/20260209_123456_abc12345.pdf",
  "file_url": "/media/uploads/ABC123/20260209_123456_abc12345.pdf",
  "file_hash": "sha256_hash_here...",
  "message": "Evidence uploaded locally. Blockchain anchoring in progress."
}
```

## What Remains Unchanged

### Blockchain Integration (100% Preserved)
✅ Smart contract calls for `anchorEvidence()`  
✅ Transaction hash storage in MySQL  
✅ SHA-256 hash anchoring on blockchain  
✅ SLA tracking and event logging  
✅ Complaint lifecycle events  
✅ Blockchain verification logic  
✅ Celery task queue for async operations  
✅ Gas configuration and transaction handling  

### API Compatibility
The API structure remains similar, only field names changed:
- `ipfs_cid` → `file_path`
- `ipfs_url` → `file_url`

## Rollback Plan (If Needed)

If you need to rollback to IPFS:

1. Revert all code changes:
   ```bash
   git checkout HEAD~1 -- backend/blockchain/
   git checkout HEAD~1 -- backend/.env
   git checkout HEAD~1 -- backend/blockchain_settings.py
   ```

2. Rollback database migration:
   ```bash
   python manage.py migrate blockchain <previous_migration_name>
   ```

3. Restore IPFS credentials in `.env`

## Benefits of This Refactor

1. **Simplified Architecture**: No external IPFS dependencies
2. **Cost Savings**: No Infura/pinning service costs
3. **Performance**: Local file access is faster
4. **Reliability**: No third-party service downtime
5. **Privacy**: Files stored on your infrastructure
6. **Blockchain Security**: SHA-256 anchoring still provides tamper-proof verification
7. **Easy Backup**: Standard file system backup tools work

## Security Considerations

1. **Access Control**: Ensure proper file permissions (755 for dirs, 644 for files)
2. **File Validation**: Validate file types and sizes before upload
3. **Path Traversal**: The service uses safe path joining to prevent directory traversal
4. **Blockchain Anchoring**: SHA-256 hash provides cryptographic proof of file integrity

## Maintenance

### Regular Tasks
1. Monitor `media/uploads/` disk space usage
2. Implement file cleanup for deleted complaints
3. Regular backups of media directory
4. Log rotation for blockchain operations

### Backup Script Example
```bash
#!/bin/bash
# backup-media.sh
BACKUP_DIR="/backups/media-$(date +%Y%m%d)"
cp -r /path/to/backend/media "$BACKUP_DIR"
echo "Media backup completed: $BACKUP_DIR"
```

## Support & Documentation

For issues or questions:
1. Check error logs in `logs/blockchain.log`
2. Verify file permissions and directory structure
3. Confirm Django settings are loaded correctly
4. Test blockchain connectivity separately

## Summary

All IPFS references have been removed and replaced with local file storage. The blockchain anchoring logic remains fully intact, providing the same level of security and verification while simplifying the architecture and reducing external dependencies.

**Status**: ✅ Refactoring Complete  
**Database Migration**: ⚠️ Required (see steps above)  
**Testing**: ⚠️ Required before production use
