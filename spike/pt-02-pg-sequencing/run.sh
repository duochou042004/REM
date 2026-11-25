#!/bin/bash
# P0-PT-02 throwaway spike: ADR-0005 / sync §3 scenarios against a pinned PostgreSQL in Podman.
# usage: WORK=<scratch dir> ./run.sh up|S1|S2|...|S9|invariants|down    Not production code.
# shortcut: race interleavings are driven with pg_sleep and fixed host sleeps, not a scheduler; fine for a spike.
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
WORK=${WORK:?set WORK to a scratch directory}
C=rem-pt02-pg
IMG=docker.io/library/postgres@sha256:aaa10f7ba7328b4a221a6c3184d83eef885bd16bf1f6de864757863156b0a4d1
q() { podman exec -i $C psql -XAtq -v ON_ERROR_STOP=1 -U postgres -d rem "$@"; }
uuid() { cat /proc/sys/kernel/random/uuid; }
ready() { for _ in $(seq 60); do podman exec $C psql -XAtq -U postgres -d rem -c 'select 1' >/dev/null 2>&1 && return 0; sleep 0.5; done; return 1; }

up() {
  mkdir -p "$WORK"
  podman run -d --name $C --network none -e POSTGRES_HOST_AUTH_METHOD=trust -e POSTGRES_DB=rem \
    -v "$HERE":/spike:ro -v "$WORK":/work $IMG \
    -c track_commit_timestamp=on -c synchronous_commit=on -c fsync=on -c shared_buffers=1GB \
    -c max_connections=300 -c deadlock_timeout=1s >/dev/null
  # the entrypoint runs a temporary server for initdb; wait until the final server is up
  for _ in $(seq 120); do podman logs $C 2>&1 | grep -q 'PostgreSQL init process complete' && break; sleep 0.5; done
  ready && q -f /spike/sql/schema.sql >/dev/null && q -c "select version(), current_setting('synchronous_commit'), current_setting('fsync'), current_setting('track_commit_timestamp')"
}

down() { podman rm -f $C >/dev/null; }

bench() {  # bench CLIENTS conv spread [-> prints tps, failures, latency]
  local c=$1 j=$(( $1 < 8 ? $1 : 8 ))
  podman exec $C pgbench -n -U postgres -f /spike/sql/send_client.pgbench -D conv=$2 -D spread=$3 \
    -c $c -j $j -T 15 --max-tries=3 --failures-detailed rem 2>&1 |
    grep -E '^(number of transactions actually processed|number of failed|number of transactions retried|latency average|tps)' | tr '\n' ';'
  echo
}

S9() {  # throughput per hot conversation, spread contrast, WAL and bytes per message
  for c in 1 4 16 64; do
    l0=$(q -c 'select pg_current_wal_lsn()'); n0=$(q -c 'select count(*) from messages')
    echo "hot conv=1 clients=$c: $(bench $c 1 0)"
    echo "  wal bytes per send: $(q -c "select round(pg_wal_lsn_diff(pg_current_wal_lsn(), '$l0') / nullif(count(*) - $n0, 0)) from messages")"
  done
  for c in 16 64; do echo "spread conv=101..164 clients=$c: $(bench $c 0 1)"; done
  q -c "vacuum analyze"
  q -c "select relname, pg_total_relation_size(oid) from pg_class where relname in ('messages','events','idempotency','outbox','search_index') order by 1" | tr '\n' ' '; echo
  q -c "select 'rows=' || (select count(*) from messages) || ' bytes_per_message=' || round((select sum(pg_total_relation_size(oid)) from pg_class where relname in ('messages','events','idempotency','outbox','search_index')) / (select count(*) from messages)::numeric)"
}

S1() {  # contiguous seq for every conversation the load wrote (I3)
  q -c "with e as (select conversation_id c, count(*) n, count(distinct seq) d, min(seq) lo, max(seq) hi from events group by 1)
        select 'conversations=' || count(*) || ' bad=' || count(*) filter (where n <> d or lo <> 1 or hi <> n or hi <> cv.last_seq)
          || ' msgs_without_event=' || (select count(*) from messages m where not exists (select 1 from events x where x.conversation_id = m.conversation_id and x.seq = m.seq))
          || ' msgs_without_outbox=' || (select count(*) from messages m where not exists (select 1 from outbox o where o.conversation_id = m.conversation_id and o.seq = m.seq))
          || ' msgs_without_idem=' || (select count(*) from messages m where not exists (select 1 from idempotency i where (i.result->>'message_id')::uuid = m.message_id))
        from e join conversations cv on cv.id = e.c where e.c = 1 or e.c between 101 and 164"
}

S2() {  # client connection lost before commit; lost ACK after commit
  local op=$(uuid) op2=$(uuid) before after
  before=$(q -c 'select last_seq from conversations where id = 2')
  podman exec -e PGAPPNAME=pt02crash $C psql -XAtq -U postgres -d rem \
    -c "select send_message(2, 2, '$op', 'before-commit'); select pg_sleep(30);" >/dev/null 2>&1 &
  sleep 1.5
  echo "terminated backend in open tx: $(q -c "select count(pg_terminate_backend(pid)) from pg_stat_activity where application_name = 'pt02crash'")"
  wait
  after=$(q -c 'select last_seq from conversations where id = 2')
  echo "before-commit: last_seq $before -> $after; rows for op: $(q -c "select count(*) from idempotency where operation_id = '$op'")"
  echo "  retry same op: $(q -c "select send_message(2, 2, '$op', 'before-commit')" | cut -c1-200) (expected status ok, seq $((before + 1)))"
  r1=$(q -c "select send_message(2, 2, '$op2', 'lost-ack')")   # committed; the client "loses" this reply
  ls1=$(q -c 'select last_seq from conversations where id = 2')
  r2=$(q -c "select send_message(2, 2, '$op2', 'lost-ack')")
  ls2=$(q -c 'select last_seq from conversations where id = 2')
  echo "lost-ack:"; python3 -I - "$r1" "$r2" "$ls1" "$ls2" <<'EOF'
import json, sys
a, b = json.loads(sys.argv[1]), json.loads(sys.argv[2])
print(f"  first {a['status']} seq={a['seq']} mid={a['message_id'][:8]}; retry {b['status']} seq={b['seq']} mid={b['message_id'][:8]}; "
      f"same_ack={a['seq'] == b['seq'] and a['message_id'] == b['message_id']}; last_seq {sys.argv[3]} -> {sys.argv[4]}")
EOF
}

S3() {  # server crash (SIGKILL of the container) under load; every ACKed send must survive (I1)
  rm -f "$WORK"/ack_s3_*.log
  for k in 1 2 3 4 5 6 7 8; do podman exec $C bash /spike/worker.sh $k 2 /work/ack_s3_$k.log crash >/dev/null 2>&1 & done
  sleep 5
  podman kill -s KILL $C >/dev/null; wait
  echo "acked lines before kill: $(cat "$WORK"/ack_s3_*.log | wc -l)"
  podman start $C >/dev/null && ready || { echo "restart failed"; return 1; }
  podman logs --since 1m $C 2>&1 | grep -E 'not properly shut down|automatic recovery|redo done' | sed 's/^.*LOG: */  log: /' | head -3
  python3 -I - "$WORK" > "$WORK/acks_s3.tsv" <<'EOF'
import json, sys, glob
for f in glob.glob(sys.argv[1] + "/ack_s3_*.log"):
    for line in open(f):
        try:
            op, js = line.split(" ", 1); r = json.loads(js)
        except ValueError:
            continue  # a line cut by the kill is not an ACK
        if r.get("status") == "ok":
            print(f"{op}\t{r['seq']}\t{r['message_id']}")
EOF
  q <<EOF
create temp table acks (op uuid, seq bigint, mid uuid);
\copy acks from '/work/acks_s3.tsv'
select 'acked_ok=' || (select count(*) from acks)
  || ' missing_after_restart=' || (select count(*) from acks a where not exists (select 1 from messages m where m.message_id = a.mid and m.seq = a.seq and m.conversation_id = 2))
  || ' committed_not_acked=' || (select count(*) from messages m where m.conversation_id = 2 and m.body = 'crash' and not exists (select 1 from acks a where a.mid = m.message_id))
  || ' conv2_events=' || (select count(*) from events where conversation_id = 2) || ' conv2_last_seq=' || (select last_seq from conversations where id = 2)
  || ' conv2_contiguous=' || (select count(distinct seq) = max(seq) and min(seq) = 1 from events where conversation_id = 2);
EOF
}

S4() {  # duplicate storm: 32 concurrent sends with one operation id, then conflicting reuse
  local op=$(uuid)
  rm -f "$WORK"/dup_*.out
  podman exec $C psql -XAtq -U postgres -d rem -c "begin; select 1 from conversations where id = 3 for update; select pg_sleep(2); commit;" >/dev/null &
  sleep 0.5
  podman exec $C bash -c "for k in \$(seq 32); do psql -XAtq -U postgres -d rem -c \"select send_message(10, 3, '$op', 'dup')\" > /work/dup_\$k.out & done; wait" &
  sleep 1.2
  echo "waiting on the conversation lock at release: $(q -c "select count(*) from pg_stat_activity where wait_event_type = 'Lock'")"
  wait
  cat "$WORK"/dup_*.out | python3 -I -c "
import json, sys, collections
rs = [json.loads(l) for l in sys.stdin if l.strip()]
print('results', len(rs), dict(collections.Counter(r['status'] for r in rs)), 'distinct seq', len({r.get('seq') for r in rs}), 'distinct mid', len({r.get('message_id') for r in rs}))"
  echo "messages for op: $(q -c "select count(*) from messages m join idempotency i on (i.result->>'message_id')::uuid = m.message_id where i.operation_id = '$op'")"
  echo "same op, other body: $(q -c "select send_message(10, 3, '$op', 'different')")"
  echo "same op, other conversation: $(q -c "select send_message(10, 101, '$op', 'dup')")"
}

S5() {  # sends racing a member removal (conv 4, user 20 removed by admin session 1)
  rm -f "$WORK"/ack_s5_*.log
  for k in a b c d; do podman exec $C bash /spike/worker.sh 20 4 /work/ack_s5_20$k.log race >/dev/null 2>&1 & done
  podman exec $C bash /spike/worker.sh 21 4 /work/ack_s5_21.log race >/dev/null 2>&1 &
  sleep 1.5
  r=$(q -c "select (remove_member(1, 4, 20))->>'seq'")
  sleep 1.5
  podman exec $C pkill -f worker.sh; wait
  echo "member.removed seq r=$r"
  q -c "select 'user20 msgs=' || count(*) || ' max_seq=' || max(seq) || ' after_r=' || count(*) filter (where seq > $r) from messages where conversation_id = 4 and sender_id = 20"
  q -c "select 'user21 msgs after r=' || count(*) from messages where conversation_id = 4 and sender_id = 21 and seq > $r"
  cat "$WORK"/ack_s5_20*.log | python3 -I -c "
import json, sys, collections
print('user20 results', dict(collections.Counter(json.loads(l.split(' ',1)[1])['status'] for l in sys.stdin if ' ' in l)))"
  local old; old=$(grep -h '"status": "ok"' "$WORK"/ack_s5_20a.log | head -1 | cut -d' ' -f1)
  echo "retry of an earlier ok op after removal: $(q -c "select send_message(20, 4, '$old', 'race')")"
  echo "new op after removal: $(q -c "select send_message(20, 4, '$(uuid)', 'race')")"
}

S6() {  # sends and a duplicate racing a session revocation (conv 5, admin session 1)
  local opa=$(uuid) t0 t1
  podman exec $C psql -XAtq -U postgres -d rem -c "select send_message(30, 5, '$opa', 'rev', 2)" > "$WORK/s6a.out" &
  sleep 0.5; t0=$(date +%s.%N)
  q -c "select revoke_session(1, 30)" >/dev/null; t1=$(date +%s.%N); wait
  echo "(a) in-flight send: $(cat "$WORK/s6a.out" | cut -c1-60)...; revocation waited $(python3 -c "print(round($t1-$t0,2))") s"
  q -c "select '    send committed before revocation: ' || (select pg_xact_commit_timestamp(m.xmin) < pg_xact_commit_timestamp(s.xmin) from messages m, sessions s where m.session_id = 30 and s.id = 30)"
  podman exec $C psql -XAtq -U postgres -d rem -c "select revoke_session(1, 31); select pg_sleep(2);" >/dev/null &
  sleep 0.5; t0=$(date +%s.%N)
  r=$(q -c "select send_message(31, 5, '$(uuid)', 'rev')"); t1=$(date +%s.%N); wait
  echo "(b) send during an open revocation: $r after waiting $(python3 -c "print(round($t1-$t0,2))") s"
  echo "(c) duplicate of (a) after the revocation: $(q -c "select send_message(30, 5, '$opa', 'rev')")"
  rm -f "$WORK"/ack_s6_*.log
  for k in a b c d; do podman exec $C bash /spike/worker.sh 32 5 /work/ack_s6_$k.log rev >/dev/null 2>&1 & done
  sleep 1.5; q -c "select revoke_session(1, 32)" >/dev/null; sleep 1
  podman exec $C pkill -f worker.sh; wait
  q -c "select '(d) session 32 msgs=' || count(*) || ' committed_after_revocation=' || count(*) filter (where pg_xact_commit_timestamp(m.xmin) > (select pg_xact_commit_timestamp(xmin) from sessions where id = 32)) from messages m where session_id = 32"
  cat "$WORK"/ack_s6_*.log | python3 -I -c "
import json, sys, collections
print('    worker results', dict(collections.Counter(json.loads(l.split(' ',1)[1])['status'] for l in sys.stdin if ' ' in l)))"
}

S7() {  # two admins revoke each other's sessions at once; §3.1 order vs actor-first control
  q -c "insert into users (id) values (50101), (50102) on conflict do nothing" >/dev/null
  for mode in true false; do
    local base=$([ $mode = true ] && echo 70000 || echo 80000)
    rm -f "$WORK"/s7_*.out
    for t in $(seq 20); do
      a=$((base + 2*t - 1)); b=$((base + 2*t))
      q -c "insert into sessions (id, user_id) values ($a, 50101), ($b, 50102)" >/dev/null
      podman exec $C bash -c "psql -XAtq -U postgres -d rem -c 'select revoke_session($a, $b, 0.3, $mode)' > /work/s7_${t}a.out 2>&1 &
        psql -XAtq -U postgres -d rem -c 'select revoke_session($b, $a, 0.3, $mode)' > /work/s7_${t}b.out 2>&1 & wait"
    done
    echo "ordered=$mode: 20 pairs: ok=$(cat "$WORK"/s7_*.out | grep -c '"ok"') session_revoked=$(cat "$WORK"/s7_*.out | grep -c session_revoked) deadlock=$(cat "$WORK"/s7_*.out | grep -c 'deadlock detected') both_revoked=$(q -c "select count(*) from (select (id - $base + 1) / 2 p from sessions where id between $base and $((base+40)) and revoked_at is not null group by 1 having count(*) = 2) x")"
  done
}

S8() {  # large-group membership transaction cost: one user row (and user event) per member
  for n in 100 1000 10000 50000; do
    for f in create dissolve; do
      local arg=$([ $f = create ] && echo "$((1000000 + n)), 1, $n" || echo "$((1000000 + n))")
      q <<EOF
select pg_current_wal_lsn() as l0, clock_timestamp() as t0 \gset
select ${f}_group($arg);
select 'n=$n $f ms=' || round(extract(epoch from clock_timestamp() - :'t0'::timestamptz) * 1000) || ' wal_bytes=' || pg_wal_lsn_diff(pg_current_wal_lsn(), :'l0');
EOF
    done
  done | grep -v '^$'
}

invariants() {  # every conversation: events seq = 1..last_seq, no holes or duplicates (I3); user streams (I9)
  q -c "select 'conversations=' || count(*) || ' bad=' || count(*) filter (where coalesce(n, 0) <> cv.last_seq or coalesce(d, 0) <> cv.last_seq or coalesce(hi, 0) <> cv.last_seq)
        from conversations cv left join (select conversation_id c, count(*) n, count(distinct seq) d, max(seq) hi from events group by 1) e on e.c = cv.id"
  q -c "select 'users_with_events=' || count(*) || ' bad=' || count(*) filter (where n <> u.last_user_seq or hi <> u.last_user_seq)
        from users u join (select user_id, count(*) n, max(user_seq) hi from user_events group by 1) e on e.user_id = u.id"
}

"$@"
