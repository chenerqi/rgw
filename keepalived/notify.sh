#!/bin/bash

TYPE=\$1
NAME=\$2
STATE=\$3

case \$STATE in
        "MASTER") echo "status: MASTER" >> /dev/stdout
		  ip addr add ${VIRTUAL_IP:-192.168.254.254}/${VIRTUAL_IP_MASK:-32} dev ${INTERFACE:-eth0} label ${INTERFACE:-eth0}:xms
      if [ "$ENABLE_LB" = "true" ]; then
		    ip addr add ${VIRTUAL_IP_LB:-192.168.254.253}/${VIRTUAL_IP_LB_MASK:-32} dev ${INTERFACE:-eth0} label ${INTERFACE:-eth0}:xms
      fi
                  exit 0
                  ;;
        "BACKUP") echo "status: BACKUP" >> /dev/stdout
		  ip addr delete ${VIRTUAL_IP:-192.168.254.254}/${VIRTUAL_IP_MASK:-32} dev ${INTERFACE:-eth0}
      if [ "$ENABLE_LB" = "true" ]; then
		    ip addr add ${VIRTUAL_IP_LB:-192.168.254.253}/${VIRTUAL_IP_LB_MASK:-32} dev ${INTERFACE:-eth0} label ${INTERFACE:-eth0}:xms
      fi
                  exit 0
                  ;;
        "FAULT")  echo "status: ERROR" >> /dev/stderr
		  ip addr delete ${VIRTUAL_IP:-192.168.254.254}/${VIRTUAL_IP_MASK:-32} dev ${INTERFACE:-eth0}
      if [ "$ENABLE_LB" = "true" ]; then
		    ip addr add ${VIRTUAL_IP_LB:-192.168.254.253}/${VIRTUAL_IP_LB_MASK:-32} dev ${INTERFACE:-eth0} label ${INTERFACE:-eth0}:xms
      fi
                  exit 0
                  ;;
        *)        echo "status : UNKNOWN" >> /dev/stderr
                  exit 1
                  ;;
esac