#!/bin/bash
# source this file with arg find to set ALL_PROXY and SSL_CERT_FILE
# otherwise just export it manually
# Ideally need to make it work like pyenv instead

# wget https://downloads.mitmproxy.org/10.4.2/mitmproxy-10.4.2-linux-x86_64.tar.gz
# tar xzf mitmproxy-10.4.2-linux-x86_64.tar.gz

MITMDUMP=/home/demo/mitmdump
MITMPORT=12347
# We cant use local host, incredibly ALL_PROXY seems to inherit into the damn comntainers during install
# mitmdump --listen-host $LOCAL
# We need a way to learn the proxmos host IP and also provide that to the conatiner
#PROXY=127.0.0.1
PROXY=172.30.42.33
CONFDIR=/tmp/.mitmproxy

# Curl proxying - vars will flow into the container it seems
# But the certs would fail then...
export ALL_PROXY=http://$PROXY:$MITMPORT
export http_proxy=http://$PROXY:$MITMPORT
export https_proxy=http://$PROXY:$MITMPORT
export SSL_CERT_FILE=$CONFDIR/mitmproxy-ca-cert.pem

# I havent worked out how to get mitmproxy to put this somewhere else

if [ "$1" == "find" ] ; then
  echo ALL_PROXY=$ALL_PROXY
  echo http_proxy=$http_proxy
  echo https_proxy=$https_proxy
  echo SSL_CERT_FILE=$SSL_CERT_FILE
  return
fi

# DONT SOURCE to get here

set -eou pipefail

mkdir -p $CONFDIR

# Because we are sourcing this we cant use REPO as an input. In theory we can use args to override, or a different var
# Assume we run it in the working copy by default
TTECK_REPO=${1:-$(pwd)}
echo TTECK_REPO=$TTECK_REPO
screen -X -S mitmdump quit || true
# killall mitmdump || true
screen -d -m -S mitmdump $MITMDUMP -v -v  -p $MITMPORT --set confdir=$CONFDIR --map-local '|raw.githubusercontent.com/tteck/Proxmox/main|'$TTECK_REPO >> /tmp/mitm.log 2>&1

# wait for it to be ready

while ! curl --output /dev/null --silent --head --fail https://raw.githubusercontent.com; do sleep 0.1 && echo -n .; done
echo ready
