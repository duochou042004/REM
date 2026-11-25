#!/bin/bash
# P0-PT-02 throwaway spike: runs inside the container. Sends with fresh operation ids and appends
# "<op> <result json>" to LOG only after psql returns, i.e. after the commit (the client's ACK).
# usage: worker.sh SESSION CONV LOG BODY [COUNT]
sess=$1 conv=$2 log=$3 body=$4 n=${5:-1000000}
for ((i = 0; i < n; i++)); do
  [ -e /work/stop ] && exit 0  # graceful stop: killing the loop would orphan psql under the postmaster (PID 1)
  op=$(cat /proc/sys/kernel/random/uuid)
  r=$(psql -XAtq -U postgres -d rem -c "select send_message($sess, $conv, '$op', '$body')") || continue
  echo "$op $r" >> "$log"
done
