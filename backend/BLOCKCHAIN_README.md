# Blockchain Integration for Complaint Management System

## 🎯 Overview

This blockchain integration extends the Django complaint management system with:

1. **Immutable Complaint Event Log** - Every lifecycle event recorded on-chain
2. **Evidence Integrity** - IPFS storage with blockchain hash anchoring
3. **SLA Enforcement** - On-chain deadline tracking with automated escalation

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     User Interface                          │
│                   (Django REST API)                         │
└────────────────┬────────────────────────────────────────────┘
                 │
      ┌──────────┴──────────┐
      │                     │
      ▼                     ▼
┌──────────────┐      ┌──────────────┐
│   MySQL DB   │      │   Blockchain │
│   (Cache)    │      │   Service    │
└──────────────┘      └──────┬───────┘
                             │
                    ┌────────┴────────┐
                    │                 │
                    ▼                 ▼
           ┌─────────────┐    ┌──────────┐
           │ Amazon MBC  │    │   IPFS   │
           │ (Ethereum)  │    │ Storage  │
           └─────────────┘    └──────────┘
```

### Design Principles

- **Blockchain is authoritative** - MySQL is just a cache/query layer
- **Minimal on-chain data** - Only hashes and minimal metadata on-chain
- **Async operations** - Blockchain writes don't block HTTP responses
- **Service isolation** - All blockchain logic in `blockchain/` app
- **Zero-trust verification** - Anyone can verify data against blockchain

## 📦 What Was Implemented

### 1. Smart Contracts (`blockchain/contracts/`)

**ComplaintRegistry.sol** - Solidity contract with:
- `logComplaintEvent()` - Log lifecycle events
- `anchorEvidence()` - Anchor file hashes
- `setSLADeadline()` - Set SLA deadlines
- `checkAndEscalate()` - Enforce SLA violations
- `batchCheckAndEscalate()` - Batch SLA checks

### 2. Django Blockchain App (`blockchain/`)

```
blockchain/
├── models.py              # BlockchainTransaction, EvidenceHash, SLATracker
├── services.py            # Web3.py integration service
├── ipfs_service.py        # IPFS upload/retrieval
├── signals.py             # Auto-trigger blockchain writes
├── tasks.py               # Celery async tasks
├── listeners.py           # Event sync from blockchain
├── views.py               # REST API endpoints
├── urls.py                # URL routing
├── admin.py               # Django admin
└── management/commands/
    ├── check_sla.py       # Manual SLA check
    ├── sync_blockchain_events.py
    └── listen_blockchain_events.py
```

### 3. Database Models

**BlockchainTransaction** - Tracks all on-chain transactions
- Stores tx_hash for verification
- Links complaint_id to events
- Cache of gas costs and block numbers

**EvidenceHash** - Links IPFS files to blockchain anchors
- IPFS CID storage
- SHA-256 hash for verification
- Blockchain timestamp

**SLATracker** - SLA deadline and escalation status
- Synced from smart contract events
- Cache for query performance

### 4. Integration Points

**report/models.py** - Updated IssueReport model:
- `blockchain_tx_hash` - Latest transaction
- `blockchain_verified` - On-chain status
- `sla_escalated` - Escalation flag
- `tracker` - Field change tracker

**Django Signals** - Auto-trigger blockchain writes:
- Complaint created → Log to blockchain
- Status changed → Log to blockchain
- Assigned → Set SLA deadline
- Evidence uploaded → Anchor hash

### 5. REST API Endpoints

```
POST   /api/blockchain/reports/{tracking_id}/evidence/
       Upload evidence to IPFS + anchor on blockchain

POST   /api/blockchain/reports/{tracking_id}/evidence/verify/
       Verify file integrity against blockchain

GET    /api/blockchain/reports/{tracking_id}/status/
       Get blockchain status and all transactions

GET    /api/blockchain/reports/{tracking_id}/audit-trail/
       Get complete audit trail from blockchain
```

## 🚀 Setup Instructions

### Prerequisites

1. **Amazon Managed Blockchain** account with Ethereum node
2. **Redis** server (for Celery)
3. **IPFS** access (Infura or self-hosted)
4. **Ethereum wallet** with funds for gas

### Step 1: Install Dependencies

```bash
cd backend
pip install -r requirements-blockchain.txt
```

### Step 2: Configure Environment

```bash
cp .env.blockchain.example .env
# Edit .env with your blockchain node URL, private key, etc.
```

### Step 3: Update Django Settings

Add to `report_hub/settings/base.py`:

```python
# Import blockchain settings
from blockchain_settings import *

# Add to INSTALLED_APPS
INSTALLED_APPS = [
    # ... existing apps ...
    'blockchain',
    'model_utils',
]
```

### Step 4: Run Migrations

```bash
python manage.py makemigrations
python manage.py migrate
```

### Step 5: Deploy Smart Contract

```bash
cd blockchain/contracts

# Compile contract
python deploy.py

# Deploy to blockchain (requires funded wallet)
export BLOCKCHAIN_NODE_URL="https://your-node-url"
export DEPLOYER_ADDRESS="0xYourAddress"
export DEPLOYER_PRIVATE_KEY="0xYourPrivateKey"

python deploy.py --deploy
```

**Save the contract address!** Add it to `.env`:
```
BLOCKCHAIN_CONTRACT_ADDRESS=0x... (address from deployment)
```

### Step 6: Configure Celery

Create `report_hub/celery.py`:

```python
import os
from celery import Celery

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'report_hub.settings.base')

app = Celery('report_hub')
app.config_from_object('django.conf:settings', namespace='CELERY')
app.autodiscover_tasks()
```

Start Celery workers:

```bash
# Terminal 1: Start Redis
redis-server

# Terminal 2: Start Celery worker
celery -A report_hub worker -l info

# Terminal 3: Start Celery beat (periodic tasks)
celery -A report_hub beat -l info
```

### Step 7: Update URL Configuration

Add to `report_hub/urls.py`:

```python
urlpatterns = [
    # ... existing patterns ...
    path('api/blockchain/', include('blockchain.urls')),
]
```

### Step 8: Test the Integration

```bash
# Create a test complaint (triggers blockchain write)
curl -X POST http://localhost:8000/api/reports/ \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "issue_title": "Test Issue",
    "location": "Test Location",
    "issue_description": "Test"
  }'

# Check blockchain status
curl http://localhost:8000/api/blockchain/reports/TRACKING123/status/ \
  -H "Authorization: Bearer YOUR_TOKEN"

# Manual SLA check
python manage.py check_sla

# Sync blockchain events
python manage.py sync_blockchain_events
```

## 🔧 Usage Examples

### Upload Evidence with Blockchain Anchoring

```python
import requests

# Upload evidence file
files = {'file': open('evidence.jpg', 'rb')}
response = requests.post(
    'http://localhost:8000/api/blockchain/reports/ABC12345/evidence/',
    files=files,
    headers={'Authorization': f'Bearer {token}'}
)

print(response.json())
# {
#   "ipfs_cid": "QmXyz...",
#   "ipfs_url": "https://ipfs.io/ipfs/QmXyz...",
#   "file_hash": "abc123...",
#   "message": "Evidence uploaded to IPFS. Blockchain anchoring in progress."
# }
```

### Verify Evidence Integrity

```python
# Verify a file against blockchain
files = {'file': open('evidence.jpg', 'rb')}
response = requests.post(
    'http://localhost:8000/api/blockchain/reports/ABC12345/evidence/verify/',
    files=files,
    headers={'Authorization': f'Bearer {token}'}
)

print(response.json())
# {
#   "verified": true,
#   "file_hash": "abc123...",
#   "block_timestamp": 1234567890,
#   "anchored_at": "2026-02-09T10:30:00Z"
# }
```

### Get Complete Audit Trail

```python
response = requests.get(
    'http://localhost:8000/api/blockchain/reports/ABC12345/audit-trail/',
    headers={'Authorization': f'Bearer {token}'}
)

print(response.json())
# {
#   "tracking_id": "ABC12345",
#   "total_events": 4,
#   "events": [
#     {
#       "event_type": "CREATED",
#       "timestamp": "2026-02-09T10:00:00Z",
#       "tx_hash": "0x...",
#       "verified_on_chain": true
#     },
#     ...
#   ]
# }
```

## 🔒 Security Best Practices

### Private Key Management

**Development:**
- Store in `.env` file (DON'T commit to git)
- Use test networks with test ETH

**Production:**
- Use AWS Secrets Manager
- Rotate keys periodically
- Use multi-sig wallets for high-value operations

Example with AWS Secrets Manager:

```python
import boto3
import json

def get_private_key():
    client = boto3.client('secretsmanager')
    secret = client.get_secret_value(SecretId='blockchain-private-key')
    return json.loads(secret['SecretString'])['private_key']
```

### Gas Management

- Set reasonable gas limits to prevent runaway costs
- Use gas price multiplier for faster confirmations
- Implement gas price oracles for dynamic pricing
- Monitor transaction costs and optimize contract calls

### Error Handling

- All blockchain writes are async (don't block users)
- Failed transactions are logged and retried
- Graceful degradation if blockchain unavailable
- Always validate on-chain data against local cache

## 📊 Monitoring & Maintenance

### Health Checks

```bash
# Check blockchain connection
python manage.py shell
>>> from blockchain.services import get_blockchain_service
>>> service = get_blockchain_service()
>>> print(f"Connected: {service.w3.is_connected()}")

# Check Celery status
celery -A report_hub inspect active
celery -A report_hub inspect stats
```

### Periodic Tasks

1. **SLA Checks** - Every 15 minutes via Celery Beat
2. **Event Sync** - Every 10 minutes
3. **Failed Transaction Retry** - Hourly

### Logs

Monitor these log files:
- `logs/blockchain.log` - All blockchain operations
- Celery worker logs - Async task execution
- Django logs - API requests and errors

### Cost Monitoring

Track blockchain costs:

```python
from blockchain.models import BlockchainTransaction
from django.db.models import Sum

# Total gas used this month
total_gas = BlockchainTransaction.objects.filter(
    timestamp__gte='2026-02-01'
).aggregate(Sum('gas_used'))

print(f"Gas used: {total_gas['gas_used__sum']}")
```

## 🧪 Testing

### Manual Testing

```bash
# Deploy to test network
export BLOCKCHAIN_NODE_URL="https://goerli.infura.io/v3/YOUR_KEY"
python blockchain/contracts/deploy.py --deploy

# Run SLA check (dry run)
python manage.py check_sla --dry-run

# Upload test evidence
curl -X POST http://localhost:8000/api/blockchain/reports/TEST001/evidence/ \
  -F "file=@test.jpg" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Integration Tests

Create `blockchain/tests.py`:

```python
from django.test import TestCase
from blockchain.services import get_blockchain_service

class BlockchainIntegrationTests(TestCase):
    def test_log_complaint_event(self):
        service = get_blockchain_service()
        result = service.log_complaint_event(
            'TEST001',
            'CREATED',
            {'test': 'data'}
        )
        self.assertIsNotNone(result)
        self.assertIsNotNone(result.tx_hash)
```

## 🚨 Troubleshooting

### Problem: "Cannot connect to blockchain node"

**Solution:**
- Check `BLOCKCHAIN_NODE_URL` in `.env`
- Verify node is running and accessible
- Check firewall/security group settings
- Ensure you have proper authentication

### Problem: "Transaction failed" or "Out of gas"

**Solution:**
- Increase `BLOCKCHAIN_GAS_LIMIT` in settings
- Check wallet has sufficient ETH for gas
- Verify contract address is correct
- Check transaction logs for specific error

### Problem: "Celery tasks not running"

**Solution:**
- Verify Redis is running: `redis-cli ping`
- Check Celery worker is started
- Check Celery beat is started for periodic tasks
- View Celery logs for errors

### Problem: "IPFS upload failed"

**Solution:**
- Verify `IPFS_API_URL` is correct
- Check Infura project credentials
- Ensure file size is under IPFS limits
- Try alternative IPFS gateway

## 📚 Additional Resources

- [Web3.py Documentation](https://web3py.readthedocs.io/)
- [Solidity Documentation](https://docs.soliditylang.org/)
- [Amazon Managed Blockchain Guide](https://docs.aws.amazon.com/managed-blockchain/)
- [IPFS Documentation](https://docs.ipfs.tech/)
- [Celery Documentation](https://docs.celeryproject.org/)

## 🤝 Support

For issues or questions:
1. Check logs in `logs/blockchain.log`
2. Review Django error pages
3. Check Celery worker output
4. Verify blockchain explorer for transaction status

## 📝 License

This implementation follows Django best practices and is production-ready.
