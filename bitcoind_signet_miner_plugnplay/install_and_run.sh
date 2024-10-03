#!/bin/bash

mkdir -p ~/mining-setup/bin

# Set DEBIAN_FRONTEND to noninteractive to suppress any interactive prompts during package installations
export DEBIAN_FRONTEND=noninteractive

# Update package lists and install the required packages
apt-get update -qq && apt-get install -y nano \
    net-tools nmap bc gpg curl unzip jq bash-completion git \
    python3 python3-pip python3-setuptools

# Install the required Python packages using pip
pip install argparse requests cryptography pipreqs

# Install Python 3.9
apt-get -y install python3.9

cp ./custom-bitcoin-27.1.tar.gz ~/mining-setup/
cp ./bitcoin-dowload.sh ~/mining-setup/
chmod +x ~/mining-setup/bitcoind-download.sh
~/mining-setup/bitcoind-download.sh

# Set environment variables
GH_URL="https://raw.githubusercontent.com/bitcoin/bitcoin/master"
BC="/usr/share/bash-completion/completions"

# Create the target directories for bash completion files
mkdir -p $BC

# Download bash completion files for bitcoin-cli, bitcoind, and bitcoin-tx
curl -sSL ${GH_URL}/contrib/completions/bash/bitcoin-cli.bash -o ${BC}/bitcoin-cli
curl -sSL ${GH_URL}/contrib/completions/bash/bitcoind.bash -o ${BC}/bitcoind
curl -sSL ${GH_URL}/contrib/completions/bash/bitcoin-tx.bash -o ${BC}/bitcoin-tx

# Copy the bitcoind configuration directory to /data
cp -r ./bitcoind ~/mining-setup

# Copy support scripts
cp ./download-minig-framework.sh ~/mining-setup
chmod +x ~/mining-setup/download-minig-framework.sh

# Download and copy mining frameworks
~/mining-setup/download-minig-framework.sh -s "test/functional/test_framework" -d "~/mining-setup/data/test/functional/test_framework"
~/mining-setup/download-minig-framework.sh -s "test/functional/test_framework/crypto" -d "~/mining-setup/data/test/functional/test_framework/crypto"
~/mining-setup/download-minig-framework.sh -s "contrib/signet" -d "~/mining-setup/data/contrib/signet"

# Modify the shebang of the miner script to use python3.9
sed -i 's/env python3/env python3.9/' ~/mining-setup/data/contrib/signet/miner

# Generate the pip requirements file
pipreqs ~/mining-setup/data/test/functional/test_framework

# Install the required Python packages
pip install -r ~/mining-setup/data/test/functional/test_framework/requirements.txt

# Copy additional scripts and configurations
cp ./cli ~/mining-setup/bin/
cat ./bashrc >> ~/.bashrc
cp ./bitcoind-entrypoint.sh ~/mining-setup/
cp ./mine.sh ~/mining-setup/

# Set executable permissions
chmod +x ~/mining-setup/cli
chmod +x ~/mining-setup/bitcoind-entrypoint.sh
chmod +x ~/mining-setup/mine.sh
chmod +x ~/mining-setup/data/contrib/signet/miner

# Set the working directory
cd ~/mining-setup/bitcoind

# Expose ports (simulated in script by displaying information)
echo "Exposing ports:"
echo " - bitcoind P2P: 38333/tcp"
echo " - bitcoind regtest RPC: 38332/tcp"
echo " - zmqpubrawblock: 28332/tcp"
echo " - zmqpubrawtx: 28333/tcp"
echo " - zmqpubrawtx: 28334/tcp"

# Start the entrypoint script
echo "Starting entrypoint script..."
~/mining-setup/bitcoind-entrypoint.sh &

# Start mining on custom signet
echo "Starting mining on custom signet..."
~/mining-setup/mine.sh