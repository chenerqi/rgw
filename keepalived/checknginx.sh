#!/bin/bash
# description:
# start nginx if nginx not runni
# if start nginx failed, stop keepalived
status=$(ps -C nginx --no-heading|wc -l)
echo $status
if [ "${status}" = "0" ]; then
    /usr/local/openresty/nginx/sbin/nginx
    status2=$(ps -C nginx --no-heading|wc -l)
    if [ "${status2}" = "0"  ]; then
        pkill -9 keepalived
    fi
fi
