"""
Solidity Smart Contract Deployment Guide
==========================================

Prerequisites:
1. Install Solidity compiler: npm install -g solc
2. Install web3.py: pip install web3
3. Set up AWS Managed Blockchain Ethereum node access

Compilation:
------------
solc --abi --bin ComplaintRegistry.sol -o build/

Or use this Python script to compile:
"""

from solcx import compile_source, install_solc
import json
import os


def compile_contract():
    """Compile the ComplaintRegistry contract"""
    
    # Install solc if needed
    try:
        install_solc('0.8.19')
    except Exception as e:
        print(f"Solc already installed or error: {e}")
    
    # Read contract source
    contract_path = os.path.join(
        os.path.dirname(__file__),
        'ComplaintRegistry.sol'
    )
    
    with open(contract_path, 'r') as f:
        contract_source = f.read()
    
    # Compile
    compiled = compile_source(
        contract_source,
        output_values=['abi', 'bin'],
        solc_version='0.8.19'
    )
    
    # Extract contract interface
    contract_id, contract_interface = compiled.popitem()
    
    # Save ABI and bytecode
    build_dir = os.path.join(os.path.dirname(__file__), 'build')
    os.makedirs(build_dir, exist_ok=True)
    
    with open(os.path.join(build_dir, 'ComplaintRegistry_abi.json'), 'w') as f:
        json.dump(contract_interface['abi'], f, indent=2)
    
    with open(os.path.join(build_dir, 'ComplaintRegistry_bytecode.txt'), 'w') as f:
        f.write(contract_interface['bin'])
    
    print("✓ Contract compiled successfully")
    print(f"  ABI saved to: {build_dir}/ComplaintRegistry_abi.json")
    print(f"  Bytecode saved to: {build_dir}/ComplaintRegistry_bytecode.txt")
    
    return contract_interface


def deploy_contract(w3, account, private_key):
    """
    Deploy contract to Ethereum network
    
    Args:
        w3: Web3 instance connected to blockchain
        account: Deployer wallet address
        private_key: Private key for signing transaction
    
    Returns:
        contract_address: Deployed contract address
    """
    
    # Compile contract
    contract_interface = compile_contract()
    
    # Create contract instance
    Contract = w3.eth.contract(
        abi=contract_interface['abi'],
        bytecode=contract_interface['bin']
    )
    
    # Build transaction
    tx = Contract.constructor().build_transaction({
        'from': account,
        'nonce': w3.eth.get_transaction_count(account),
        'gas': 3000000,
        'gasPrice': w3.eth.gas_price,
    })
    
    # Sign transaction
    signed_tx = w3.eth.account.sign_transaction(tx, private_key)
    
    # Send transaction
    print("Deploying contract...")
    tx_hash = w3.eth.send_raw_transaction(signed_tx.rawTransaction)
    
    # Wait for receipt
    print(f"Transaction hash: {tx_hash.hex()}")
    print("Waiting for confirmation...")
    tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    
    contract_address = tx_receipt['contractAddress']
    print(f"✓ Contract deployed at: {contract_address}")
    
    return contract_address


if __name__ == '__main__':
    """
    Run this script to compile or deploy:
    
    Compile only:
        python deploy.py
    
    Deploy (requires environment variables):
        BLOCKCHAIN_NODE_URL=https://your-node-url
        DEPLOYER_ADDRESS=0x...
        DEPLOYER_PRIVATE_KEY=0x...
        python deploy.py --deploy
    """
    
    import sys
    from web3 import Web3
    
    if '--deploy' in sys.argv:
        # Load config from environment
        node_url = os.getenv('BLOCKCHAIN_NODE_URL')
        account = os.getenv('DEPLOYER_ADDRESS')
        private_key = os.getenv('DEPLOYER_PRIVATE_KEY')
        
        if not all([node_url, account, private_key]):
            print("Error: Set BLOCKCHAIN_NODE_URL, DEPLOYER_ADDRESS, and DEPLOYER_PRIVATE_KEY")
            sys.exit(1)
        
        # Connect to blockchain
        w3 = Web3(Web3.HTTPProvider(node_url))
        
        if not w3.is_connected():
            print("Error: Cannot connect to blockchain node")
            sys.exit(1)
        
        print(f"Connected to blockchain (Chain ID: {w3.eth.chain_id})")
        
        # Deploy
        contract_address = deploy_contract(w3, account, private_key)
        
        print("\n" + "="*60)
        print("IMPORTANT: Save this contract address to your .env file:")
        print(f"BLOCKCHAIN_CONTRACT_ADDRESS={contract_address}")
        print("="*60)
    else:
        # Just compile
        compile_contract()
