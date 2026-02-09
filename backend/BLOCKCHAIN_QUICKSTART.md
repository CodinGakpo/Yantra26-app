# Blockchain Integration - Quick Start Guide

## 🚀 5-Minute Setup

Follow these steps to get blockchain integration running:

### 1. Install Dependencies (2 min)

```bash
cd backend
pip install -r requirements-blockchain.txt
```

### 2. Configure Environment (1 min)

```bash
cp .env.blockchain.example .env
```

Edit `.env` and set **minimum required values**:

```bash
# Your Ethereum node URL (get from Amazon MBC or Infura)
BLOCKCHAIN_NODE_URL=https://your-node-url

# Your wallet private key (KEEP SECRET!)
BLOCKCHAIN_PRIVATE_KEY=0xYourPrivateKey

# After deploying contract, add this
BLOCKCHAIN_CONTRACT_ADDRESS=0xContractAddress

# IPFS (use Infura or public gateway)
IPFS_API_URL=https://ipfs.infura.io:5001
IPFS_GATEWAY_URL=https://ipfs.io
```

### 3. Run Migrations (1 min)

```bash
python manage.py makemigrations blockchain
python manage.py migrate
```

### 4. Deploy Smart Contract (1 min)

```bash
cd blockchain/contracts
python deploy.py --deploy
```

**Copy the contract address from output and add to `.env`**

### 5. Start Services

```bash
# Terminal 1: Django
python manage.py runserver

# Terminal 2: Redis (required for Celery)
redis-server

# Terminal 3: Celery Worker
celery -A report_hub worker -l info

# Terminal 4: Celery Beat (for SLA checks)
celery -A report_hub beat -l info
```

## ✅ Test It Works

### Test 1: Create Complaint

```bash
curl -X POST http://localhost:8000/api/reports/ \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "issue_title": "Test Issue",
    "location": "Test Location",
    "issue_description": "Testing blockchain integration"
  }'
```

### Test 2: Check Blockchain Status

```bash
curl http://localhost:8000/api/blockchain/reports/TRACKING_ID/status/ \
  -H "Authorization: Bearer YOUR_TOKEN"
```

You should see blockchain transactions!

## 🎯 What Happens Automatically

When you create a complaint:

1. ✅ Django creates record in MySQL
2. ✅ Signal triggers Celery task
3. ✅ Celery task logs event to blockchain
4. ✅ Transaction hash stored in MySQL
5. ✅ SLA deadline set on blockchain

All in the background—no blocking!

## 🔧 Common Issues

**"Cannot connect to blockchain"**
- Check `BLOCKCHAIN_NODE_URL` is correct
- Verify node is running

**"Celery tasks not running"**
- Make sure Redis is running: `redis-cli ping`
- Check Celery worker is started

**"Out of gas"**
- Make sure wallet has ETH for gas fees
- Check you're on the right network

## 📞 Need Help?

Check the full documentation: [BLOCKCHAIN_README.md](BLOCKCHAIN_README.md)

## 🔒 Security Reminder

**NEVER commit `.env` to git!**

Add to `.gitignore`:
```
.env
*.key
*.pem
```

---

That's it! You now have blockchain-integrated complaint management. 🎉
