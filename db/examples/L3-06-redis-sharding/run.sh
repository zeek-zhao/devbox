#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."

COMPOSE_FILE="${DB_COMPOSE_FILE:-$PWD/docker/docker-compose.yml}"
dc() { docker compose -f "$COMPOSE_FILE" "$@"; }
replica="devbox-db-redis-replica-${BASHPID}"
cleanup() {
  docker rm -f "$replica" >/dev/null 2>&1 || true
  dc rm -sf redis-node1 redis-node2 redis-node3 >/dev/null 2>&1 || true
}
trap cleanup EXIT

dc --profile cluster up -d redis-node1 redis-node2 redis-node3 >&2 || {
  echo "ERROR: failed to start Redis cluster nodes (profile=cluster)" >&2
  exit 1
}

wait_node() {
  local node="$1"
  for _ in $(seq 1 60); do
    if dc exec -T "$node" redis-cli -a devbox --no-auth-warning PING 2>/dev/null | grep -qx PONG; then
      return 0
    fi
    sleep 1
  done
  echo "ERROR: Redis cluster node $node did not become ready" >&2
  dc ps >&2 || true
  return 1
}
wait_node redis-node1
wait_node redis-node2
wait_node redis-node3

dc exec -T redis-node1 redis-cli -a devbox --no-auth-warning --cluster create \
  redis-node1:6379 redis-node2:6379 redis-node3:6379 \
  --cluster-replicas 0 --cluster-yes >&2 || {
  echo "ERROR: failed to distribute all Redis cluster slots across three masters" >&2
  exit 1
}

master1_id="$(dc exec -T redis-node1 redis-cli -a devbox --no-auth-warning CLUSTER MYID)"
master2_id="$(dc exec -T redis-node2 redis-cli -a devbox --no-auth-warning CLUSTER MYID)"
master3_id="$(dc exec -T redis-node3 redis-cli -a devbox --no-auth-warning CLUSTER MYID)"
# 这里原来做「从 master2 挪 1 个槽给 master3，把分配规整成 5461/5461/5462」。
# 但 redis-cli --cluster create 是按**地址排序**分配槽段的，compose 的容器 IP 是动态的,
# 哪台拿到 5462 那一段每次可能不同；规整动作隐含假设「node2 拿 5462」，
# 一旦容器 IP 顺序变了，后面的槽数校验就假红（实测 6 次红 1 次）。
# 改成只校验「三主覆盖 16384 个槽」，不假设谁拿哪一段。

cluster_info() {
  dc exec -T redis-node2 redis-cli -a devbox --no-auth-warning CLUSTER INFO | tr -d '\r'
}
for _ in $(seq 1 60); do
  if cluster_info | grep -qx 'cluster_state:ok'; then break; fi
  sleep 1
done
cluster_info | grep -qx 'cluster_state:ok' || {
  echo "ERROR: Redis cluster did not reach cluster_state:ok after slot assignment" >&2
  cluster_info >&2 || true
  exit 1
}
cluster_info | grep -qx 'cluster_slots_assigned:16384' &&
  cluster_info | grep -qx 'cluster_slots_ok:16384' || {
  echo "ERROR: Redis cluster slot coverage is incomplete" >&2
  cluster_info >&2 || true
  exit 1
}

nodes="$(dc exec -T redis-node1 redis-cli -a devbox --no-auth-warning CLUSTER NODES)"
masters="$(printf '%s\n' "$nodes" | awk '$3 ~ /master/ && $3 !~ /fail/ {n++} END {print n+0}')"
[ "$masters" = 3 ] || {
  echo "ERROR: expected three Redis masters, found $masters" >&2
  printf '%s\n' "$nodes" >&2
  exit 1
}
slot_count() {
  printf '%s\n' "$1" | awk -v id="$2" '
    $1 == id {
      for (i = 9; i <= NF; i++) {
        if ($i ~ /^[0-9]+-[0-9]+$/) {
          split($i, range, "-")
          count += range[2] - range[1] + 1
        } else if ($i ~ /^[0-9]+$/) {
          count++
        }
      }
      print count + 0
      exit
    }'
}
total_slots=0
for id in "$master1_id" "$master2_id" "$master3_id"; do
  n="$(slot_count "$nodes" "$id")"
  [ "$n" -ge 1 ] || {
    echo "ERROR: master $id owns no slots" >&2
    printf '%s\n' "$nodes" >&2
    exit 1
  }
  total_slots=$((total_slots + n))
done
[ "$total_slots" = 16384 ] || {
  echo "ERROR: expected 16384 slots across three masters, found $total_slots" >&2
  printf '%s\n' "$nodes" >&2
  exit 1
}

# 槽位归属按 CLUSTER NODES 里真实的分段算，不靠「node1 一定是 0-5460」这种假设。
slot_owner_id() {
  printf '%s\n' "$nodes" | awk -v s="$1" '
    $3 ~ /master/ && $3 !~ /fail/ {
      for (i = 9; i <= NF; i++) {
        if ($i ~ /^[0-9]+-[0-9]+$/) {
          split($i, r, "-")
          if (s + 0 >= r[1] + 0 && s + 0 <= r[2] + 0) { print $1; exit }
        } else if ($i ~ /^[0-9]+$/) {
          if (s + 0 == $i + 0) { print $1; exit }
        }
      }
    }'
}
node_of_id() {
  case "$1" in
    "$master1_id") printf 'redis-node1\n' ;;
    "$master2_id") printf 'redis-node2\n' ;;
    "$master3_id") printf 'redis-node3\n' ;;
    *) printf '\n' ;;
  esac
}

key="db:l3_06:cross:1"
slot="$(dc exec -T redis-node1 redis-cli -a devbox --no-auth-warning CLUSTER KEYSLOT "$key" | tr -d '\r')"
owner_id="$(slot_owner_id "$slot")"
owner_node="$(node_of_id "$owner_id")"
[ -n "$owner_node" ] || {
  echo "ERROR: slot $slot is not owned by any of the three masters" >&2
  printf '%s\n' "$nodes" >&2
  exit 1
}
# 从「不拥有这个槽」的节点发写命令，必须拿到 MOVED，且槽号要对得上
if [ "$owner_node" = redis-node1 ]; then sender=redis-node2; else sender=redis-node1; fi
set_response="$(dc exec -T "$sender" redis-cli -a devbox --no-auth-warning SET "$key" cluster-value 2>&1 | tr -d '\r')" || {
  echo "ERROR: cross-node write command failed before MOVED response: $set_response" >&2
  exit 1
}
[[ "$set_response" == "MOVED $slot "* ]] || {
  echo "ERROR: expected MOVED $slot from non-owning $sender, received: $set_response" >&2
  exit 1
}
set_routed="$(dc exec -T "$sender" redis-cli -c -a devbox --no-auth-warning SET "$key" cluster-value 2>/dev/null | tr -d '\r' | tail -n 1)"
[ "$set_routed" = OK ] || { echo "ERROR: cluster-aware write did not follow MOVED to the owning node" >&2; exit 1; }
if [ "$owner_node" = redis-node3 ]; then reader=redis-node1; else reader=redis-node3; fi
read_value="$(dc exec -T "$reader" redis-cli -c -a devbox --no-auth-warning GET "$key" 2>/dev/null | tr -d '\r' | tail -n 1)"
[ "$read_value" = cluster-value ] || {
  echo "ERROR: redirected cross-node read returned an unexpected value: $read_value" >&2
  exit 1
}

ask_key="db:l3_06:ask:1"
ask_slot="$(dc exec -T redis-node1 redis-cli -a devbox --no-auth-warning CLUSTER KEYSLOT "$ask_key" | tr -d '\r')"
ask_owner_id="$(slot_owner_id "$ask_slot")"
ask_owner_node="$(node_of_id "$ask_owner_id")"
[ -n "$ask_owner_node" ] || {
  echo "ERROR: slot $ask_slot is not owned by any of the three masters" >&2
  exit 1
}
# 迁移目标必须是另一个 master
ask_import_node=""
for n in redis-node1 redis-node2 redis-node3; do
  [ "$n" = "$ask_owner_node" ] && continue
  ask_import_node="$n"
  break
done
ask_import_id="$(dc exec -T "$ask_import_node" redis-cli -a devbox --no-auth-warning CLUSTER MYID | tr -d '\r')"
dc exec -T "$ask_owner_node" redis-cli -a devbox --no-auth-warning CLUSTER SETSLOT "$ask_slot" MIGRATING "$ask_import_id" >/dev/null
dc exec -T "$ask_import_node" redis-cli -a devbox --no-auth-warning CLUSTER SETSLOT "$ask_slot" IMPORTING "$ask_owner_id" >/dev/null
ask_response="$(dc exec -T "$ask_owner_node" redis-cli -a devbox --no-auth-warning GET "$ask_key" 2>&1 | tr -d '\r')" || {
  echo "ERROR: ASK probe command failed" >&2
  exit 1
}
[[ "$ask_response" == ASK\ * ]] || {
  echo "ERROR: expected ASK from the migrating slot, received: $ask_response" >&2
  exit 1
}
for node in redis-node1 redis-node2 redis-node3; do
  dc exec -T "$node" redis-cli -a devbox --no-auth-warning CLUSTER SETSLOT "$ask_slot" STABLE >/dev/null
done

tag_a="$(dc exec -T redis-node1 redis-cli -a devbox --no-auth-warning CLUSTER KEYSLOT '{user1}:a')"
tag_b="$(dc exec -T redis-node1 redis-cli -a devbox --no-auth-warning CLUSTER KEYSLOT '{user1}:b')"
[ "$tag_a" = "$tag_b" ] || { echo "ERROR: Redis hash-tag keys did not map to the same slot" >&2; exit 1; }

master_id="$(dc exec -T redis-node1 redis-cli -a devbox --no-auth-warning CLUSTER MYID)"
node1_id="$(dc ps -q redis-node1)"
image="$(docker inspect -f '{{.Image}}' "$node1_id")"
network="$(docker inspect -f '{{range $name, $value := .NetworkSettings.Networks}}{{$name}}{{end}}' "$node1_id")"
docker run -d --name "$replica" --network "$network" --network-alias "$replica" "$image" \
  redis-server --requirepass devbox --masterauth devbox --cluster-enabled yes \
  --cluster-config-file nodes.conf --cluster-node-timeout 5000 --appendonly yes >/dev/null || {
  echo "ERROR: could not start a temporary Redis replica for failover validation" >&2
  exit 1
}
replica_id="$(docker exec "$replica" redis-cli -a devbox --no-auth-warning CLUSTER MYID)"
dc exec -T redis-node1 redis-cli -a devbox --no-auth-warning --cluster add-node \
  "$replica:6379" redis-node1:6379 --cluster-slave --cluster-master-id "$master_id" >&2 || {
  echo "ERROR: failed to attach temporary replica to the first master" >&2
  exit 1
}

replica_ready=0
for _ in $(seq 1 60); do
  role="$(docker exec "$replica" redis-cli -a devbox --no-auth-warning INFO replication | awk -F: '/^role:/ {gsub("\r", "", $2); print $2}')"
  if [ "$role" = slave ]; then replica_ready=1; break; fi
  sleep 1
done
[ "$replica_ready" = 1 ] || { echo "ERROR: temporary replica did not synchronize with its master" >&2; exit 1; }
# 原主此刻真实拥有的槽数（可能是 5461，也可能不是 —— 取决于 create 时的地址排序）
master1_slots="$(slot_count "$nodes" "$master1_id")"
dc stop redis-node1 >&2 || {
  echo "ERROR: could not stop the original master to trigger replica promotion" >&2
  exit 1
}
docker exec "$replica" redis-cli -a devbox --no-auth-warning CLUSTER FAILOVER TAKEOVER >/dev/null || {
  echo "ERROR: stopped master's replica could not take over its slots" >&2
  exit 1
}

failover_ok=0
for _ in $(seq 1 60); do
  current="$(dc exec -T redis-node2 redis-cli -a devbox --no-auth-warning CLUSTER NODES)"
  replica_line="$(printf '%s\n' "$current" | awk -v id="$replica_id" '$1 == id {print; exit}')"
  replica_slots="$(slot_count "$current" "$replica_id")"
  if [ -n "$replica_line" ] &&
    printf '%s\n' "$replica_line" | awk '$3 ~ /master/ && NF >= 9 {found=1} END {exit !found}' &&
    [ "$replica_slots" = "$master1_slots" ] &&
    cluster_info | grep -qx 'cluster_state:ok'; then
    failover_ok=1
    break
  fi
  sleep 1
done
[ "$failover_ok" = 1 ] || {
  echo "ERROR: cluster did not recover with the promoted replica owning slots" >&2
  printf '%s\n' "${current:-}" >&2
  cluster_info >&2 || true
  exit 1
}

echo "redis cluster state: ok"
echo "redis masters: three"
echo "redis slots: complete"
echo "MOVED redirection and cross-node read: yes"
echo "ASK redirection during slot migration: yes"
echo "hash-tag co-location: yes"
echo "failover and slot takeover: recovered"
