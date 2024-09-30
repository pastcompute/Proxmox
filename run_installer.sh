#!/bin/bash
F="$(basename "${1%%.sh}")"
rm -f "${F}.result.txt"
MYUSER=$LOGNAME

POSTFUNC=$(cat <<EOF
echo -e "\033[mRunning POSTFUNC." >&2
pwd >&2
echo SSL_CERT_FILE=\$SSL_CERT_FILE
echo WGETRC=\$WGETRC
chown $MYUSER:$MYUSER trun.log
if test -e "${F}.result.txt" ; then
  chown $MYUSER:$MYUSER "${F}.result.txt"
  source "${F}.result.txt"
  source \${APP}.override.conf
  post_install_common || true
  post_install || true   # this is in the conf file...
  echo "DONE - You are in screen (as sudo)."
  export CTID
  export APP
  env PS1="\${APP} \${CTID}: \[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\\\$ \[\]" /bin/bash --norc -i
else
  echo "DONE - You are in screen. Failed to determine CTID - no ${F}.result.txt."
  env PS1="${F} - Failed: \[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\\\$ \[\]" /bin/bash --norc -i
fi
EOF
)
# echo "$POSTFUNC" ; exit

export WGETRC=/tmp/proxy_wrap_tteck_wget.rc

# WARNING: wget needs --ca-certificate=$SSL_CERT_FILE  in .wgetrc so we dont need to patch wget commands
# We also need to wap this into the container...
echo 'ca_certificate = '$SSL_CERT_FILE'' > $WGETRC

# annoyingly it wont inherit sudo passwd into screen?
# https://superuser.com/questions/1157168/can-i-make-sudo-share-cached-credentials-between-terminals
screen -Logfile trun.log -L -i sudo -E bash -c "bash '$1' || true ; bash -s <<<${POSTFUNC}"
