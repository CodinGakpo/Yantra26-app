# Integration Checklist - Step by Step

This checklist ensures you integrate blockchain correctly into your existing Django app.

## ✅ Pre-Integration Checklist

- [ ] Django app is working and tested
- [ ] MySQL database is set up
- [ ] User authentication is working
- [ ] Complaint creation/management is working
- [ ] Redis is installed (for Celery)
- [ ] You have access to Ethereum node (Amazon MBC or Infura)
- [ ] You have an Ethereum wallet with test ETH

## 📦 Installation Steps

### Step 1: Install Python Packages

```bash
cd backend
pip install -r requirements-blockchain.txt
```

**Verify installation:**
```bash
python -c "import web3; print('✓ web3 installed')"
python -c "import celery; print('✓ celery installed')"
```

### Step 2: Add Blockchain App to Settings

Edit `report_hub/settings/base.py`:

```python
INSTALLED_APPS = [
    # ... existing apps ...
    'blockchain',  # ADD THIS
    'model_utils',  # ADD THIS (for field tracking)
]
```

### Step 3: Import Blockchain Settings

At the end of `report_hub/settings/base.py`:

```python
# Import blockchain configuration
from blockchain_settings import *
```

### Step 4: Initialize Celery

Edit `report_hub/__init__.py`:

```python
from .celery import app as celery_app

__all__ = ('celery_app',)
```

### Step 5: Update URL Configuration

Edit `report_hub/urls.py`:

```python
urlpatterns = [
    # ... existing patterns ...
    path('api/blockchain/', include('blockchain.urls')),  # ADD THIS
]
```

### Step 6: Run Migrations

```bash
python manage.py makemigrations blockchain
python manage.py makemigrations report  # For updated IssueReport model
python manage.py migrate
```

**Verify migrations:**
```bash
python manage.py showmigrations blockchain
```

### Step 7: Configure Environment

```bash
cp .env.blockchain.example .env
```

Edit `.env` with your values:

```bash
# REQUIRED
BLOCKCHAIN_NODE_URL=https://your-ethereum-node-url
BLOCKCHAIN_PRIVATE_KEY=0xYourPrivateKey
BLOCKCHAIN_CONTRACT_ADDRESS=0x...  # After deployment

# RECOMMENDED
IPFS_API_URL=https://ipfs.infura.io:5001
IPFS_GATEWAY_URL=https://ipfs.io
CELERY_BROKER_URL=redis://localhost:6379/0
```

### Step 8: Deploy Smart Contract

```bash
cd blockchain/contracts

# Set deployment credentials
export BLOCKCHAIN_NODE_URL="https://your-node-url"
export DEPLOYER_ADDRESS="0xYourWalletAddress"
export DEPLOYER_PRIVATE_KEY="0xYourPrivateKey"

# Deploy
python deploy.py --deploy
```

**SAVE THE CONTRACT ADDRESS!** Add it to `.env`:
```
BLOCKCHAIN_CONTRACT_ADDRESS=0x... # from deployment output
```

### Step 9: Test Blockchain Connection

```bash
python manage.py shell
```

```python
from blockchain.services import get_blockchain_service

service = get_blockchain_service()
print(f"Connected: {service.w3.is_connected()}")
print(f"Chain ID: {service.w3.eth.chain_id}")
print(f"Latest block: {service.w3.eth.block_number}")
```

If all print successfully, you're connected! ✅

### Step 10: Start All Services

```bash
# Terminal 1: Redis
redis-server

# Terminal 2: Django
python manage.py runserver

# Terminal 3: Celery Worker
celery -A report_hub worker -l info

# Terminal 4: Celery Beat
celery -A report_hub beat -l info
```

## 🧪 Testing the Integration

### Test 1: Create a Complaint

```bash
# Get auth token first
TOKEN="your_jwt_token"

# Create complaint
curl -X POST http://localhost:8000/api/reports/ \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "issue_title": "Test Blockchain Integration",
    "location": "Test Location",
    "issue_description": "Testing if blockchain logging works"
  }'
```

**Expected:**
- Complaint created in MySQL
- Celery task dispatched (check worker logs)
- Blockchain transaction sent (check logs)
- Transaction hash stored in database

### Test 2: Check Blockchain Status

```bash
# Get tracking ID from previous response
TRACKING_ID="ABC12345"

curl http://localhost:8000/api/blockchain/reports/$TRACKING_ID/status/ \
  -H "Authorization: Bearer $TOKEN"
```

**Expected JSON response:**
```json
{
  "tracking_id": "ABC12345",
  "blockchain_verified": true,
  "events": [
    {
      "event_type": "CREATED",
      "tx_hash": "0x...",
      "block_number": 12345,
      "status": "CONFIRMED"
    }
  ],
  "sla_status": {
    "deadline": 1234567890,
    "escalated": false,
    "time_remaining_seconds": 172800
  }
}
```

### Test 3: Upload Evidence

```bash
curl -X POST http://localhost:8000/api/blockchain/reports/$TRACKING_ID/evidence/ \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@test_image.jpg"
```

**Expected:**
- File uploaded to IPFS
- IPFS CID returned
- Blockchain anchoring task dispatched
- Hash anchored on blockchain

### Test 4: Manual SLA Check

```bash
python manage.py check_sla --dry-run
```

**Expected output:**
```
Checking for SLA violations...
DRY RUN MODE - No blockchain transactions
Found 0 complaints past deadline
✓ SLA check complete
```

### Test 5: Sync Blockchain Events

```bash
python manage.py sync_blockchain_events
```

**Expected output:**
```
Syncing blockchain events...
✓ Sync complete:
  • Complaint events: 1
  • Evidence events: 0
  • Escalation events: 0
  • SLA events: 1
```

## 🐛 Troubleshooting

### Issue: Celery tasks not executing

**Check:**
1. Redis is running: `redis-cli ping` → should return `PONG`
2. Celery worker is running: check Terminal 3
3. Check Celery logs for errors

**Fix:**
```bash
# Restart Celery worker
celery -A report_hub worker -l info --purge
```

### Issue: Blockchain connection fails

**Check:**
1. `.env` has correct `BLOCKCHAIN_NODE_URL`
2. Node is accessible (try in browser)
3. Wallet has ETH for gas

**Fix:**
```bash
# Test connection
python manage.py shell
>>> from web3 import Web3
>>> w3 = Web3(Web3.HTTPProvider('YOUR_NODE_URL'))
>>> print(w3.is_connected())
```

### Issue: Migrations fail

**Fix:**
```bash
# Reset blockchain migrations
python manage.py migrate blockchain zero
rm blockchain/migrations/0*.py
python manage.py makemigrations blockchain
python manage.py migrate
```

### Issue: IPFS upload fails

**Check:**
1. IPFS_API_URL is correct
2. Infura credentials (if using Infura)

**Fix:**
Try public gateway:
```bash
IPFS_API_URL=https://ipfs.io:5001
```

## 📊 Monitoring

### Check Celery Status

```bash
celery -A report_hub inspect active
celery -A report_hub inspect stats
```

### Check Blockchain Transactions

```bash
python manage.py shell
```

```python
from blockchain.models import BlockchainTransaction

# Recent transactions
txs = BlockchainTransaction.objects.all()[:10]
for tx in txs:
    print(f"{tx.complaint_id} - {tx.event_type} - {tx.status}")
```

### View Logs

```bash
# Celery worker logs
tail -f celery_worker.log

# Blockchain logs
tail -f logs/blockchain.log

# Django logs
tail -f logs/django.log
```

## ✅ Integration Complete!

If all tests pass, your blockchain integration is working! 🎉

### What's Working:
- ✅ Complaints logged to blockchain automatically
- ✅ Evidence anchored on blockchain + IPFS
- ✅ SLA tracking with automated escalation
- ✅ Complete audit trail available
- ✅ Integrity verification working

### Next Steps:
1. Test with real complaints
2. Monitor gas costs
3. Set up production environment
4. Configure AWS Secrets Manager for production
5. Set up monitoring and alerts

## 🔒 Production Checklist

Before going to production:

- [ ] Move private key to AWS Secrets Manager
- [ ] Set up proper logging and monitoring
- [ ] Configure gas price strategies
- [ ] Set up backup Redis instance
- [ ] Test failover scenarios
- [ ] Set up alerts for SLA escalations
- [ ] Document procedures for team
- [ ] Set up blockchain explorer monitoring
- [ ] Test with high load
- [ ] Set up cost monitoring

## 📞 Support

If you encounter issues:
1. Check logs first
2. Review error messages
3. Test individual components
4. Check the full README: [BLOCKCHAIN_README.md](BLOCKCHAIN_README.md)

---

**Congratulations on integrating blockchain into your complaint management system! 🚀**
