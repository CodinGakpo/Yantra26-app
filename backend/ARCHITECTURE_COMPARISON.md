# Architecture Comparison: IPFS vs Local Storage

## Before: IPFS-Based Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                          User Upload                             │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Django Backend                              │
│                                                                   │
│  ┌───────────────────────────────────────────────────┐          │
│  │          blockchain/views.py                       │          │
│  │  upload_evidence_with_blockchain()                 │          │
│  └───────────────────┬───────────────────────────────┘          │
│                      │                                            │
│                      ▼                                            │
│  ┌───────────────────────────────────────────────────┐          │
│  │      blockchain/ipfs_service.py                    │          │
│  │      IPFSService.upload_file()                     │          │
│  └───────────────────┬───────────────────────────────┘          │
└────────────────────────┼────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                  IPFS (Infura Gateway)                           │
│                  ❌ External Dependency                           │
│                  ❌ Costs Money                                   │
│                  ❌ Third-party Downtime Risk                     │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼ Returns IPFS CID
┌─────────────────────────────────────────────────────────────────┐
│                      MySQL Database                              │
│                                                                   │
│  EvidenceHash:                                                   │
│  - complaint_id                                                  │
│  - file_hash (SHA-256)                                           │
│  - ipfs_cid  ← Stored                                            │
│  - tx_hash                                                       │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Blockchain (Sepolia)                            │
│                                                                   │
│  Smart Contract:                                                 │
│  - anchorEvidence(complaint_id, file_hash)                       │
│  - ✅ Tamper-proof verification                                  │
└─────────────────────────────────────────────────────────────────┘
```

## After: Local Storage Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                          User Upload                             │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Django Backend                              │
│                                                                   │
│  ┌───────────────────────────────────────────────────┐          │
│  │          blockchain/views.py                       │          │
│  │  upload_evidence_with_blockchain()                 │          │
│  └───────────────────┬───────────────────────────────┘          │
│                      │                                            │
│                      ▼                                            │
│  ┌───────────────────────────────────────────────────┐          │
│  │      blockchain/ipfs_service.py                    │          │
│  │      LocalFileStorageService.upload_file()         │          │
│  └───────────────────┬───────────────────────────────┘          │
└────────────────────────┼────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│              Local File System (media/uploads/)                  │
│                  ✅ No External Dependency                        │
│                  ✅ No Extra Costs                                │
│                  ✅ Fast & Reliable                               │
│                                                                   │
│  /media/uploads/                                                 │
│    └── ABC123/                                                   │
│        ├── 20260209_123456_abc12345.pdf                          │
│        └── 20260209_130000_def67890.jpg                          │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼ Returns file_path
┌─────────────────────────────────────────────────────────────────┐
│                      MySQL Database                              │
│                                                                   │
│  EvidenceHash:                                                   │
│  - complaint_id                                                  │
│  - file_hash (SHA-256)                                           │
│  - file_path ← Stored (uploads/ABC123/file.pdf)                 │
│  - tx_hash                                                       │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Blockchain (Sepolia)                            │
│                                                                   │
│  Smart Contract:                                                 │
│  - anchorEvidence(complaint_id, file_hash)                       │
│  - ✅ Tamper-proof verification (UNCHANGED)                      │
└─────────────────────────────────────────────────────────────────┘
```

## Key Differences

| Aspect | IPFS (Before) | Local Storage (After) |
|--------|---------------|----------------------|
| **File Storage** | External (Infura IPFS) | Local file system |
| **Identifier** | IPFS CID (Qm...) | File path (uploads/...) |
| **Cost** | $$$ per GB + bandwidth | Included in hosting |
| **Speed** | Network-dependent | Direct disk access |
| **Reliability** | Third-party service | Under your control |
| **Complexity** | Higher (API integration) | Lower (standard FS) |
| **Blockchain** | Hash anchored ✅ | Hash anchored ✅ |
| **Security** | SHA-256 verification ✅ | SHA-256 verification ✅ |
| **Dependencies** | requests, Infura API | Python stdlib only |

## Data Flow Comparison

### IPFS Flow
```
File Upload → IPFS API → Get CID → Store CID → Compute Hash → Anchor on Blockchain
              ↓
         Network Call
         (Slow, $$$)
```

### Local Storage Flow
```
File Upload → Save Locally → Get Path → Store Path → Compute Hash → Anchor on Blockchain
              ↓
         Disk Write
         (Fast, Free)
```

## Benefits Summary

### ✅ What Improved
- **Performance**: Local disk I/O faster than network calls
- **Cost**: No external service fees
- **Reliability**: No third-party downtime
- **Simplicity**: Fewer moving parts
- **Control**: Files under your management
- **Privacy**: Data stays on your infrastructure

### ✅ What Stayed the Same
- **Blockchain Anchoring**: SHA-256 hash still anchored
- **Tamper Detection**: File integrity verification unchanged
- **Transaction Tracking**: On-chain proof preserved
- **Security Model**: Cryptographic guarantees maintained

## File Organization

### Directory Structure
```
backend/
├── media/
│   ├── .gitkeep
│   └── uploads/
│       ├── ABC123/          ← Complaint ID
│       │   ├── 20260209_123456_abc12345.pdf
│       │   └── 20260209_130000_def67890.jpg
│       ├── DEF456/
│       │   └── 20260209_140000_xyz99999.png
│       └── GHI789/
│           └── 20260209_150000_qwerty12.docx
└── ...
```

### File Naming Convention
```
Format: YYYYMMDD_HHMMSS_<unique_id>.<extension>

Examples:
- 20260209_123456_abc12345.pdf
- 20260209_145320_def67890.jpg
- 20260209_183045_xyz11111.png

Benefits:
- Chronological sorting
- No name collisions
- Easy to find by date
- Preserves file extension
```

## API Response Comparison

### Before (IPFS)
```json
{
  "ipfs_cid": "QmX3F4...abc123",
  "ipfs_url": "https://ipfs.io/ipfs/QmX3F4...abc123",
  "file_hash": "d4f3c8b2a1e9...sha256",
  "message": "Evidence uploaded to IPFS..."
}
```

### After (Local Storage)
```json
{
  "file_path": "uploads/ABC123/20260209_123456_abc12345.pdf",
  "file_url": "/media/uploads/ABC123/20260209_123456_abc12345.pdf",
  "file_hash": "d4f3c8b2a1e9...sha256",
  "message": "Evidence uploaded locally..."
}
```

## Blockchain Integration (Unchanged)

```solidity
// Smart Contract Function (No Changes)
function anchorEvidence(
    string memory _complaintId,
    bytes32 _fileHash
) public returns (bytes32) {
    // Store hash on blockchain
    evidenceHashes[_complaintId][_fileHash] = block.timestamp;
    emit EvidenceAnchored(_complaintId, _fileHash, block.timestamp);
    return keccak256(abi.encodePacked(_complaintId, _fileHash));
}
```

**✅ The blockchain sees no difference - it only cares about the hash!**

## Migration Path

```
Step 1: Code Changes         ✅ DONE
Step 2: Configuration         ✅ DONE
Step 3: Database Migration    ⚠️  PENDING
Step 4: Directory Setup       ⚠️  PENDING
Step 5: Testing              ⚠️  PENDING
Step 6: Production Deploy    ⚠️  PENDING
```

---

**Conclusion**: Same security guarantees, simpler architecture, lower costs, better performance!
