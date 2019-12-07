#!/bin/bash

function rempgr_startup_operation_retry() {
  while true; do
    echo "Running repmgr startup operation: $STARTUP_OPERATION..."
    repmgr -f /etc/repmgr.conf node check --role ||
    repmgr -f /etc/repmgr.conf $STARTUP_OPERATION --force && return 0
    sleep 1
  done
}

# If recovery.conf is present in the data directory, node is standby
function get_startup_operation() {
  if  [ -f "$PGDATA/recovery.conf" ]; then
    echo "standby register"
  else
    echo "primary register"
 fi
}

function wait_for_postgresql_master_repmgr() {
  rm -rf "$PGDATA"
  while true; do
    echo "Waiting for Repmgr primary (postgresql-primary) to be ready for cloning..."
    repmgr -h postgresql-primary -U repmgr -d repmgr -f /etc/repmgr.conf standby clone --dry-run && return 0
    sleep 1
  done
}

function generate_repmgr_config() {
cat >> "/etc/repmgr.conf" <<EOF
node_id='${NODE_ID}'
node_name='${NODE_NAME}'
conninfo='host=${NODE_NAME} user=repmgr dbname=repmgr connect_timeout=2'
data_directory='${PGDATA}'
use_replication_slots = 1
failover = automatic
use_primary_conninfo_password = true
promote_command='repmgr standby promote'
follow_command='repmgr standby follow -W --upstream-node-id=%n'

primary_notification_timeout=60
repmgrd_standby_startup_timeout=60
standby_disconnect_on_failover=true
sibling_nodes_disconnect_timeout=30
EOF
cat >> "/var/lib/pgsql/.pgpass" <<EOF
*:5432:replication:repmgr:${REPMGR_PASSWORD}
*:5432:repmgr:repmgr:${REPMGR_PASSWORD}
EOF
chmod 0600 /var/lib/pgsql/.pgpass
}

function generate_repmgr_pg_hba_config() {
  cat >> "$PGDATA/pg_hba.conf" <<EOF
#
# Custom OpenShift repmgr configuration starting at this point.
#
local replication  repmgr     trust
host  replication  repmgr all md5

local repmgr       repmgr     trust
host  repmgr       repmgr all md5
EOF
}

function create_user_repmgr() {
  echo "CREATING repmgr USER and DATABASE"
  if [ -v ENABLE_REPMGR ]; then
    createuser -s repmgr
    createdb --owner=repmgr repmgr
    psql -c 'ALTER USER repmgr SET search_path TO repmgr, "$user", public;'
  fi
}
