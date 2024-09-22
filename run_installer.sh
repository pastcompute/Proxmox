#!/bin/bash
F="$(basename "${1%%.sh}")"
rm -f "${F}.result.txt"

POSTFUNC=$(cat <<EOF
chmod a+w trun.log
chmod a+w "${F}.result.txt"
source "${F}.result.txt"
source \${APP}.override.conf
post_install
echo "DONE - You are in screen."
export CTID
export APP
env PS1="\${APP} \${CTID}: \[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\\\$ \[\]" /bin/bash --norc -i
EOF
)

#sudo -E screen -Logfile trun.log -L -i bash -c 'bash '$1' || true ; ${POSTFUNC}'
sudo -E screen -Logfile trun.log -L -i bash -c "bash '$1' || true ; bash -s <<<${POSTFUNC}"
