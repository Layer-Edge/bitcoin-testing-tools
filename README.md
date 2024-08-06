# bitcoin-testing-tools

This repository aims to build a bitcoin test framework based on signet.
Docker is extensively used to provide:
* a bitcoin node that mines bitcoin on a custom signet

### Preparation

First of all, you have o make sure that port 60602 is reachable from all over the internet. 

On ubuntu you can install `ufw` with
```
sudo apt install -y ufw
```
Then you need to set some default configuration and enable the firewall:
```
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw logging off
sudo ufw enable
```
#### Miner

The system is thought to have a stand-alone machine on which the bitcoin miner node and core-clightning node run

```
docker-compose -f miner_signet.yml up
``` 

From the "miner" can be useful to retrieve, the bitcoin core, the electrum server, and the faucet addresses with the following commands:

```
# Bitcoin Core Tor address
echo "Bitcoin tor addr: $(docker exec btc_sig_miner cli getnetworkinfo | jq -r '.localaddresses[].address')"

# Bitcoin Signetchallenge
echo "Bitcoin $(docker exec btc_sig_miner cat /bitcoind/bitcoin.conf | grep signetchallenge)"

# Electrum Server address
echo "Electrum server tor addr: $(docker exec tor cat /var/lib/tor/hidden_service_electrs/hostname)"

# Bitcoin Faucet  address
echo "Bitcoin faucet tor addr: $(docker exec tor cat /var/lib/tor/hidden_service_faucet/hostname)"
```
