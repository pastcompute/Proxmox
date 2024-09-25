#!/bin/bash
# source this file with arg find to set ALL_PROXY and SSL_CERT_FILE
# otherwise just export it manually
# Ideally need to make it work like pyenv instead
#
# At present this is all dreadfully insecure but it gets the job done for the moment

# wget https://downloads.mitmproxy.org/10.4.2/mitmproxy-10.4.2-linux-x86_64.tar.gz
# tar xzf mitmproxy-10.4.2-linux-x86_64.tar.gz

MITMDUMP=/home/demo/mitmdump
MITMPORT=12347
# We cant use local host, incredibly ALL_PROXY seems to inherit into the damn comntainers during install
# In the future we might be able to make a local bridge network to fix that
# mitmdump --listen-host $LOCAL
MYIP=$(ip  -j a show dev vmbr0|jq '.[].addr_info|first( .[] | select(.family == "inet"))|.local' -r)
PROXY=${TTECK_PROXY:-$MYIP}
CONFDIR=/tmp/.mitmproxy

test -e "$MITMDUMP" || { echo "mitmdump not found!" ; exit 1; }

# Curl proxying - vars will flow into the container it seems
# But the certs would fail then...
export ALL_PROXY=http://$PROXY:$MITMPORT
export http_proxy=http://$PROXY:$MITMPORT
export https_proxy=http://$PROXY:$MITMPORT
export SSL_CERT_FILE=$CONFDIR/mitmproxy-ca-cert.pem

# I havent worked out how to get mitmproxy to put this somewhere else

if [ "$1" == "find" ] ; then
  echo export ALL_PROXY=$ALL_PROXY
  echo export http_proxy=$http_proxy
  echo export https_proxy=$https_proxy
  echo export SSL_CERT_FILE=$SSL_CERT_FILE
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

if [ $? -ne 0 ] ; then echo "Failed to start mitmdump screen session" ; exit 1 ; fi

# wait for it to be ready

while ! curl --output /dev/null --silent --head --fail https://raw.githubusercontent.com; do sleep 0.1 && echo -n .; done
echo ready
