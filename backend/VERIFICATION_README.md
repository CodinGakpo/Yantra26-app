# 🔍 Blockchain Integration Verification Guide

**Last Updated**: February 10, 2026  
**Network**: Sepolia Ethereum Testnet (Chain ID: 11155111)  
**Status**: ✅ Operational

---

## 📋 Quick Start

### Prerequisites Check

Run the preflight check first:

```bash
cd /Users/avi19/Documents/projects/hackathons/devsoc26/backend
source .venv/bin/activate
python preflight_check.py
```

**Expected output:**
```
🚀 Blockchain Integration Preflight Check
=========================================

✅ Python version: 3.13.7
✅ All required packages installed
✅ Django configured
✅ Environment variables valid
✅ Sepolia network connected (Block: 10226150+)
✅ Contract address configured

All systems ready! ✈️
```

### Run Verification

```bash
python verify_blockchain_integration.py
```

---

## 🛠️ Verification Tools Overview

### 1. preflight_check.py

**Purpose**: Validates environment before running verification

**What it checks:**
- Python version compatibility (3.8+)
- Required packages (Web3.py, Django, eth-account, colorama)
- Django settings configuration
- Environment variables (.env file)
- Blockchain network connectivity (Sepolia)
- Smart contract accessibility

**When to use:**
- Before first run
- After changing configuration
- When troubleshooting connection issues
- After environment updates

**Output:**
- ✅ Green checkmarks = All good
- ❌ Red X = Issue found with explanation

### 2. verify_blockchain_integration.py

**Purpose**: Comprehensive blockchain integration verification

**What it verifies:**
- Database records (BlockchainTransaction, EvidenceHash)
- Transaction receipts from Sepolia blockchain
- Event logs from smart contract
- Hash integrity (data vs blockchain)
- Transaction status (success/failure)
- Gas usage statistics

**When to use:**
- After deploying new complaints
- Daily/weekly integrity checks
- Before production deployment
- After smart contract changes
- When investigating data inconsistencies

**Output:**
- Colored summary report
- Per-transaction verification status
- Statistics (success rate, gas usage)
- Error details for failed transactions

---

## 📊 Verification Report Structure

### Sample Output

```
🔍 Blockchain Integration Verification Report
==============================================
Generated: 2026-02-10 14:30:00
Network: Sepolia (Chain ID: 11155111)

📋 Database Statistics
---------------------
BlockchainTransaction records: 156
EvidenceHash records: 89
Total records to verify: 245

🔗 Blockchain Connection
-----------------------
Connected: ✅
Current block: 10226150
Network: Sepolia Testnet

📦 Verification Results
----------------------
✅ TX db01234: CREATED event for COMP-001 (Block: 10226100)
   Hash match: ✅
   Gas used: 125,432

✅ TX db01235: EVIDENCE_UPLOADED for COMP-001 (Block: 10226105)
   Hash match: ✅
   Gas used: 98,765

⚠️  TX db01236: Receipt not found (may be pending)

❌ TX db01237: Hash mismatch!
   Expected: 0xabc123...
   Actual: 0xdef456...

📈 Summary
---------
Total verified: 245
Successful: 243 (99.2%)
Failed: 1 (0.4%)
Pending: 1 (0.4%)

💰 Gas Statistics
----------------
Total gas used: 12,543,210
Average per transaction: 51,196
Estimated cost: 0.0627 ETH (~$125 USD)
```

---

## 🔧 Configuration

### Environment Variables Required

Create `.env` file in backend directory:

```bash
# Blockchain Configuration
BLOCKCHAIN_NETWORK=sepolia
BLOCKCHAIN_NODE_URL=https://sepolia.infura.io/v3/YOUR_INFURA_KEY
BLOCKCHAIN_PRIVATE_KEY=0xYOUR_PRIVATE_KEY_HERE
BLOCKCHAIN_CONTRACT_ADDRESS=0xYOUR_CONTRACT_ADDRESS

# Optional
BLOCKCHAIN_GAS_LIMIT=500000
BLOCKCHAIN_GAS_PRICE_MULTIPLIER=1.1
```

### Django Settings

Verification scripts use: `report_hub.settings.local`

Ensure these are properly configured:
- [blockchain_settings.py](blockchain_settings.py) - Blockchain-specific settings
- [report_hub/settings/local.py](report_hub/settings/local.py) - Imports blockchain settings
- [report_hub/settings/base.py](report_hub/settings/base.py) - Has 'blockchain' in INSTALLED_APPS

---

## 🎯 Common Use Cases

### Case 1: Verify All Recent Transactions

```bash
# Run full verification
python verify_blockchain_integration.py

# Save output to file
python verify_blockchain_integration.py > verification_report.txt 2>&1
```

### Case 2: Check Specific Complaint

```bash
# Filter in Django shell
python manage.py shell

from blockchain.models import BlockchainTransaction
from blockchain.services import get_blockchain_service

service = get_blockchain_service()
txs = BlockchainTransaction.objects.filter(complaint_id='COMP-123')

for tx in txs:
    receipt = service.w3.eth.get_transaction_receipt(tx.transaction_hash)
    print(f"Status: {'✅ Success' if receipt.status == 1 else '❌ Failed'}")
    print(f"Block: {receipt.blockNumber}")
    print(f"Gas: {receipt.gasUsed}")
```

### Case 3: Verify Evidence Hash Integrity

```bash
python manage.py shell

from blockchain.models import EvidenceHash
import hashlib
import os

evidence = EvidenceHash.objects.get(id=1)

# Recalculate hash from file
with open(evidence.file_path, 'rb') as f:
    calculated_hash = hashlib.sha256(f.read()).hexdigest()

print(f"Stored hash: {evidence.evidence_hash}")
print(f"Calculated: {calculated_hash}")
print(f"Match: {'✅' if calculated_hash == evidence.evidence_hash else '❌'}")
```

### Case 4: Gas Cost Analysis

```bash
python manage.py shell

from blockchain.models import BlockchainTransaction
from django.db.models import Sum, Avg, Count

stats = BlockchainTransaction.objects.aggregate(
    total_gas=Sum('gas_used'),
    avg_gas=Avg('gas_used'),
    count=Count('id')
)

print(f"Total transactions: {stats['count']}")
print(f"Total gas: {stats['total_gas']:,}")
print(f"Average gas: {stats['avg_gas']:,.0f}")

# Cost at 50 Gwei
gwei = 50
cost_eth = (stats['total_gas'] * gwei) / 1e9
cost_usd = cost_eth * 2000  # Assuming $2000/ETH

print(f"Estimated cost: {cost_eth:.4f} ETH (~${cost_usd:.2f} USD)")
```

---

## 🐛 Troubleshooting

### Issue: preflight_check.py fails with "Module not found"

**Error:**
```
❌ Required packages missing: web3, django, eth-account
```

**Solution:**
```bash
source .venv/bin/activate
pip install -r requirements.txt
```

### Issue: "Connection refused" to blockchain

**Error:**
```
❌ Blockchain connection failed: Cannot connect to https://sepolia.infura.io/...
```

**Solutions:**
1. Check `BLOCKCHAIN_NODE_URL` in `.env`
2. Verify Infura key is valid
3. Test connection:
   ```bash
   curl -X POST $BLOCKCHAIN_NODE_URL \
     -H "Content-Type: application/json" \
     -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
   ```
4. Try alternative RPC:
   ```bash
   export BLOCKCHAIN_NODE_URL=https://rpc.sepolia.org
   ```

### Issue: "Django settings module not found"

**Error:**
```
ModuleNotFoundError: No module named 'report_hub.settings.development'
```

**Solution:**
Scripts are configured for `report_hub.settings.local`. Verify this file exists:
```bash
ls -l report_hub/settings/local.py
```

If using different settings:
```bash
export DJANGO_SETTINGS_MODULE=report_hub.settings.production
python verify_blockchain_integration.py
```

### Issue: "No such table: blockchain_blockchaintransaction"

**Error:**
```
django.db.utils.OperationalError: no such table: blockchain_blockchaintransaction
```

**Solution:**
```bash
python manage.py makemigrations blockchain
python manage.py migrate
```

### Issue: "Hash mismatch" errors in verification

**Cause:** Data modified after blockchain submission

**Investigation:**
```bash
python manage.py shell

from blockchain.models import BlockchainTransaction
import hashlib, json

tx = BlockchainTransaction.objects.get(transaction_hash='0x...')
print(f"Stored payload: {tx.event_payload}")
print(f"Stored hash: {tx.event_hash}")

# Recalculate
recalculated = hashlib.sha256(
    json.dumps(tx.event_payload, sort_keys=True).encode()
).hexdigest()

print(f"Recalculated: {recalculated}")
print(f"Match: {recalculated == tx.event_hash}")
```

### Issue: "Python 3.13 pkg_resources error"

**Error:**
```
ModuleNotFoundError: No module named 'pkg_resources'
```

**Solution:**
```bash
pip install setuptools
# or
pip install 'packaging>=23.1,<24'
```

### Issue: Verification shows "0 records found"

**This is normal for:**
- Fresh installation
- No complaints created yet
- New database

**To test:**
```bash
# Create test transaction via Django shell
python manage.py shell

from blockchain.services import get_blockchain_service
service = get_blockchain_service()

result = service.log_complaint_event(
    complaint_id='TEST-001',
    event_type='CREATED',
    event_data={'test': 'data', 'timestamp': '2026-02-10'}
)

print(f"Transaction: {result.tx_hash}")
print(f"Block: {result.block_number}")

# Now run verification
exit()
python verify_blockchain_integration.py
```

---

## 📅 Verification Schedule

### Recommended Frequency

**Development:**
- After each major code change
- Before committing to version control
- Ad-hoc when troubleshooting

**Staging:**
- Daily overnight runs
- After deployment
- Before production promotion

**Production:**
- Daily scheduled verification
- Weekly comprehensive audit
- Real-time monitoring for critical operations

### Automated Scheduling

**Using cron (Unix/Linux/Mac):**

```bash
# Edit crontab
crontab -e

# Add daily verification at 2 AM
0 2 * * * cd /path/to/backend && source .venv/bin/activate && python verify_blockchain_integration.py > logs/verification_$(date +\%Y\%m\%d).log 2>&1
```

**Using Django management command:**

Create `blockchain/management/commands/verify_blockchain.py`:

```python
from django.core.management.base import BaseCommand
from blockchain.models import BlockchainTransaction, EvidenceHash
# ... verification logic ...

class Command(BaseCommand):
    help = 'Verify blockchain integration'
    
    def handle(self, *args, **options):
        # Run verification
        self.stdout.write('Running verification...')
        # ... verification code ...
```

Then:
```bash
python manage.py verify_blockchain
```

---

## 📈 Monitoring & Alerts

### Key Metrics to Track

1. **Verification Success Rate**
   - Target: > 99%
   - Alert if: < 95%

2. **Gas Usage Trends**
   - Monitor for sudden spikes
   - Alert if: 2x above average

3. **Transaction Latency**
   - Target: < 60 seconds to confirmation
   - Alert if: > 300 seconds

4. **Hash Mismatch Rate**
   - Target: 0%
   - Alert if: > 0.1%

### Setting Up Alerts

**Example with Python:**

```python
# In verification script
success_rate = (successful / total) * 100

if success_rate < 95:
    send_alert(
        subject="⚠️ Blockchain Verification Alert",
        message=f"Success rate dropped to {success_rate:.1f}%",
        recipients=["devops@example.com"]
    )
```

**Integration with monitoring tools:**
- Datadog
- New Relic
- Sentry
- Prometheus + Grafana

---

## 🧪 Testing the Verification System

### Unit Tests

Create `blockchain/tests/test_verification.py`:

```python
from django.test import TestCase
from blockchain.models import BlockchainTransaction
from unittest.mock import Mock, patch

class VerificationTests(TestCase):
    def setUp(self):
        self.tx = BlockchainTransaction.objects.create(
            transaction_hash='0x123...',
            complaint_id='TEST-001',
            event_type='CREATED',
            event_payload={'data': 'test'},
            event_hash='abc123...'
        )
    
    @patch('web3.eth.Eth.get_transaction_receipt')
    def test_verify_transaction(self, mock_receipt):
        mock_receipt.return_value = Mock(
            status=1,
            blockNumber=123456,
            gasUsed=100000
        )
        
        # Run verification
        # ... assert results ...
```

Run tests:
```bash
python manage.py test blockchain.tests.test_verification
```

### Integration Tests

```bash
# Full end-to-end test
python manage.py test blockchain --keepdb

# With coverage
pip install coverage
coverage run --source='blockchain' manage.py test blockchain
coverage report
```

---

## 📚 Additional Resources

### Related Files

- [BLOCKCHAIN_README.md](blockchain/logs/BLOCKCHAIN_README.md) - Architecture overview
- [verify_blockchain_integration.py](verify_blockchain_integration.py) - Main verification script
- [preflight_check.py](preflight_check.py) - Environment validator
- [blockchain_settings.py](blockchain_settings.py) - Configuration settings
- [ISSUE_RESOLUTION_SUMMARY.md](ISSUE_RESOLUTION_SUMMARY.md) - Setup troubleshooting

### External Documentation

- **[Web3.py](https://web3py.readthedocs.io/)** - Python Ethereum library
- **[Sepolia Testnet](https://sepolia.dev/)** - Test network information
- **[Etherscan Sepolia](https://sepolia.etherscan.io/)** - Block explorer
- **[Infura](https://infura.io/)** - RPC node provider
- **[Django](https://docs.djangoproject.com/)** - Web framework

### Command Reference

```bash
# Environment
source .venv/bin/activate                    # Activate virtual environment
pip install -r requirements.txt              # Install dependencies

# Verification
python preflight_check.py                    # Check prerequisites
python verify_blockchain_integration.py      # Run full verification
python verify_blockchain_integration.py > report.txt  # Save report

# Django
python manage.py migrate                     # Apply migrations
python manage.py shell                       # Interactive shell
python manage.py check                       # Check configuration

# Blockchain queries
python -c "from web3 import Web3; w3=Web3(Web3.HTTPProvider('$BLOCKCHAIN_NODE_URL')); print(f'Block: {w3.eth.block_number}')"
```

---

## 🎓 Best Practices

### 1. Run Preflight Before Verification

Always validate environment first:
```bash
./preflight_check.py && ./verify_blockchain_integration.py
```

### 2. Regular Verification Schedule

Don't wait for issues - verify proactively:
- Development: After changes
- Staging: Daily
- Production: Daily + after deployments

### 3. Save Verification Reports

Keep audit trail:
```bash
mkdir -p logs/verification
python verify_blockchain_integration.py > logs/verification/$(date +%Y%m%d_%H%M%S).log 2>&1
```

### 4. Monitor Trends

Track metrics over time:
- Success rates
- Gas usage
- Transaction counts
- Error patterns

### 5. Document Anomalies

When verification fails:
1. Save full report
2. Note transaction hashes
3. Check blockchain explorer
4. Document resolution
5. Update troubleshooting guide

### 6. Test Smart Contract Changes

Before deploying contract updates:
1. Deploy to testnet
2. Run verification on old transactions
3. Create new test transactions
4. Verify both work correctly

---

## 📞 Support & Feedback

### Getting Help

1. **Check this guide** - Most issues documented here
2. **Review logs** - Check verification output
3. **Blockchain explorer** - https://sepolia.etherscan.io/
4. **Django shell** - Interactive debugging
5. **Team contact** - With transaction hashes and error messages

### Reporting Issues

Include:
- Verification report output
- Transaction hash(es)
- Error messages
- Environment details (Python version, OS)
- Steps to reproduce

### Improving This Guide

Contributions welcome:
- Document new error patterns
- Add use cases
- Improve troubleshooting steps
- Update command examples

---

**Last Updated**: February 10, 2026  
**Maintained by**: DevSoc26 Team  
**Status**: Production Ready ✅
