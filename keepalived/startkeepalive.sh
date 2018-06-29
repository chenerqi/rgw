#!/bin/bash

#set env
source ./keepalive.env
echo $VIRTUAL_IP
echo $MCAST_SRC_IP
# set localtime
ln -sf /usr/share/zoneinfo/$LOCALTIME /etc/localtime
function replace_vars() {
echo '------------'
echo "$(<$2)"
echo '----------'
  eval "cat <<EOF
$(<$2)
EOF
  " > $1
}

replace_vars '/etc/keepalived/keepalived.conf' 'keepalived.conf'
replace_vars '/etc/keepalived/notify.sh' 'notify.sh'
cp checknginx.sh /etc/keepalived/checknginx.sh
chmod +x /etc/keepalived/notify.sh 
chmod +x /etc/keepalived/checknginx.sh 

if [[ -f /var/run/keepalived.pid ]]; then
  rm -f /var/run/keepalived.pid
fi

# Run
/usr/sbin/keepalived -D -f /etc/keepalived/keepalived.conf -l -d
systemctl enable keepalived
