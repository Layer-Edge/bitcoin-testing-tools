ARG OS=ubuntu
ARG OS_VER=focal
FROM ${OS}:${OS_VER} as bitcoind-install

# Install dependencies
RUN DEBIAN_FRONTEND=noninteractive \
  apt-get update -qq && apt-get install -y nano  \
  net-tools nmap bc gpg curl unzip jq bash-completion git \
  python3 python3-pip python3-setuptools && \
  pip install argparse requests cryptography pipreqs

RUN DEBIAN_FRONTEND=noninteractive \
  apt-get -y install python3.9

# Install bitcoind
ENV BITCOIND_VER="24.0.1"
COPY bitcoind-download.sh /usr/local/bin
RUN chmod +x /usr/local/bin/bitcoind-download.sh
RUN bitcoind-download.sh

# Install runtime scripts, bash-completion and configuration files

# bash completion for bitcoind and bitcoin-cli
ENV GH_URL https://raw.githubusercontent.com/bitcoin/bitcoin/master
ENV BC /usr/share/bash-completion/completions
ADD $GH_URL/contrib/completions/bash/bitcoin-cli.bash $BC/bitcoin-cli
ADD $GH_URL/contrib/completions/bash/bitcoind.bash $BC/bitcoind
ADD $GH_URL/contrib/completions/bash/bitcoin-tx.bash $BC/bitcoin-tx

# Copy bitcoind configuration directory
COPY bitcoind /data

# Copy support scripts
COPY download-minig-framework.sh /usr/local/bin
RUN chmod +x /usr/local/bin/download-minig-framework.sh
RUN download-minig-framework.sh -s "test/functional/test_framework" -d "/data/test/functional/test_framework"
RUN download-minig-framework.sh -s "test/functional/test_framework/crypto" -d "/data/test/functional/test_framework/crypto"
RUN download-minig-framework.sh -s "contrib/signet" -d "/data/contrib/signet"
RUN sed -i 's/env python3/env python3.9/' /data/contrib/signet/miner
RUN pipreqs /data/test/functional/test_framework
RUN pip install -r /data/test/functional/test_framework/requirements.txt

COPY cli /usr/local/bin
COPY bashrc /root/.bashrc

COPY bitcoind-entrypoint.sh /usr/local/bin
COPY mine.sh /usr/local/bin
RUN chmod +x /usr/local/bin/cli
RUN chmod +x /usr/local/bin/bitcoind-entrypoint.sh
RUN chmod +x /usr/local/bin/mine.sh
RUN chmod +x /data/contrib/signet/miner

# bitcoind P2P
EXPOSE 38333/tcp
# bitcoind regtest RPC
EXPOSE 38332/tcp
# zmqpubrawblock
EXPOSE 28332/tcp
EXPOSE 28333/tcp
EXPOSE 28334/tcp

WORKDIR /bitcoind
ENTRYPOINT ["/usr/local/bin/bitcoind-entrypoint.sh"]

# Start mining on custom signet
CMD ["/usr/local/bin/mine.sh"]

