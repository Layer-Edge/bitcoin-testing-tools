#!/bin/bash
set -Eeuo pipefail

# Move bitcoin.conf to /bitcoind
if [ -f "~/mining-setup/data/bitcoin.conf" ]; then
    mv ~/mining-setup/data/bitcoin.conf ~/mining-setup/bitcoind/bitcoin.conf
    ln -s ~/mining-setup/bitcoind ~/mining-setup
    # If not is assumed that the bitcoin.conf is already in /bitcoind
fi

# Check if there is already the 'signetchallenge' option in 'bitcoin.conf' different from the default
# 'signetchallenge=00000000' added to not download any chain.
echo "===================================="
echo "Signetchallenge creation process"
while read -r line
do
    # Check line by line
    if [[ "$line" == *"signetchallenge=00000000"* ]]; then
        SIGNETCHALLENGE=false
        elif [[ "$line" == *"signetchallenge="* ]]; then
        echo "'signetchallenge' param already present in bitcoin.conf"
        echo "$line"
        SIGNETCHALLENGE=true
    fi
done < "~/mining-setup/bitcoind/bitcoin.conf"

if [ $SIGNETCHALLENGE = false ]; then
    # Create a new signetchallenge
    # Start bitcoind
    echo "Starting bitcoind..."
    bitcoind -datadir=~/mining-setup/bitcoind -daemon 2>&1 > /dev/null

    # Wait for bitcoind startup
    until bitcoin-cli -datadir=~/mining-setup/bitcoind -rpcwait getblockchaininfo  > /dev/null 2>&1
    do
        echo -n "."
        sleep 1
    done
    echo "bitcoind started."
    echo "===================================="
    
    # Create a new wallet
    # Uncomment the following line if a custom wallet name is require and comment the `WALLET="wallet"` line.
    # read -p "Enter the name of the wallet: " WALLET
    WALLET="wallet"
    bitcoin-cli -datadir=~/mining-setup/bitcoind -named createwallet wallet_name="$WALLET" descriptors=true 2>&1 > /dev/null
    
    # Get the signet script from the 86 descriptor
    ADDR=$(bitcoin-cli -datadir=~/mining-setup/bitcoind getnewaddress)
    SCRIPT=$(bitcoin-cli -datadir=~/mining-setup/bitcoind getaddressinfo $ADDR | jq -r ".scriptPubKey")
    sed -i "s/signetchallenge=00000000/signetchallenge=$SCRIPT/" ~/mining-setup/bitcoind/bitcoin.conf
    
    
    # Dumping descriptor wallet privatekey
    WALLETFILE="${WALLET}_privkey.txt"
    bitcoin-cli -datadir=~/mining-setup/bitcoind listdescriptors true | jq -r ".descriptors | .[].desc" >> "~/mining-setup/bitcoind/${WALLETFILE}"
    
    # Wait for bitcoind shutdown
    echo "Waiting for bitcoind to stop."
    bitcoin-cli -datadir=~/mining-setup/bitcoind stop &
    wait
    echo "bitcoind stopped."
    # Removing any downloaded timechain
    rm -rf ~/mining-setup/bitcoind/signet/ &
    wait
fi

# Start bitcoind
echo "Restarting bitcoind..."
bitcoind -datadir=~/mining-setup/bitcoind -daemon

# Wait for bitcoind startup
until bitcoin-cli -datadir=~/mining-setup/bitcoind -rpcwait getblockchaininfo  > /dev/null 2>&1
do
    echo -n "."
    sleep 1
done
echo
echo "bitcoind started"

if [ $SIGNETCHALLENGE = false ]; then
    # If there is any wallet, create a descriptor wallet
    bitcoin-cli -datadir=~/mining-setup/bitcoind -named createwallet wallet_name="$WALLET" blank=true descriptors=true 2>&1 > /dev/null
    echo "================================================"
    echo "Importing descriptors for the private key:"
    line_count=0
    while read line; do
        # Increment the line counter
        line_count=$((line_count+1))
        
        # Check if the line count is even or odd
        if [ $((line_count % 2)) -eq 0 ]; then
            is_even="true"
        else
            is_even="false"
        fi
        
        
        DESCRIPTORS="
        {
            \"desc\": \"${line}\",
            \"timestamp\": 0,
            \"active\": true,
            \"internal\": ${is_even},
            \"range\": [
                0,
                999
            ]
        }"
        
        DESCRIPTORS="[${DESCRIPTORS//[$'\t\r\n ']}]"
        
        bitcoin-cli -datadir=~/mining-setup/bitcoind importdescriptors "$DESCRIPTORS" 2>&1 > /dev/null
        
    done < "~/mining-setup/bitcoind/${WALLETFILE}"
    echo "$(bitcoin-cli -datadir=~/mining-setup/bitcoind listdescriptors)"
    echo "================================================"
else
    # If restarting, load the wallet that already exists, so don't fail if it does,
    # just load the existing wallet:
    echo "================================================"
    echo "Loading the main wallet:"
    WALLET=$(ls ~/mining-setup/bitcoind/signet/wallets -1 | head -1 | tail -1)
    bitcoin-cli -datadir=/bitcoind loadwallet "$WALLET" 2>&1 >/dev/null
    echo "Bitcoin core wallet \"$WALLET\" loaded."
    echo "================================================"
fi

# Get the signet magic string from bitcoind debug logs


if [ -f "/bitcoind/sig_magic.txt" ]; then
    # If the file exists, check if the magic string is the same
    echo "Signet magic: $(cat ~/mining-setup/bitcoind/sig_magic.txt)"
else
    # If the file doesn't exist, create it
    SIG_MAGIC=`cat ~/mining-setup/bitcoind/signet/debug.log | grep -oP 'Signet derived magic \(message start\): \K[a-f0-9]+'`
    echo $SIG_MAGIC > ~/mining-setup/bitcoind/sig_magic.txt
fi

# Executing CMD
exec "$@"

