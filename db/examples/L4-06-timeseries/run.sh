#!/usr/bin/env bash
# L4-06-timeseries · 时序数据选型
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"
NS=l4_06_timeseries
psql_quiet() { tb psql -h postgres -U devbox -d devbox -t -A -q -v ON_ERROR_STOP=1 -c "$1"; }

psql_quiet "DROP SCHEMA IF EXISTS $NS CASCADE; CREATE SCHEMA $NS;
CREATE TABLE $NS.narrow (
  measured_at date NOT NULL,
  metric text NOT NULL,
  value numeric(8,2) NOT NULL
);
CREATE TABLE $NS.wide (
  measured_at date PRIMARY KEY,
  cpu numeric(8,2) NOT NULL,
  memory numeric(8,2) NOT NULL
);
INSERT INTO $NS.narrow VALUES
  ('2026-01-01','cpu',10),('2026-01-01','memory',40),
  ('2026-01-02','cpu',20),('2026-01-02','memory',50),
  ('2026-01-03','cpu',30),('2026-01-03','memory',60);
INSERT INTO $NS.wide VALUES
  ('2026-01-01',10,40),('2026-01-02',20,50),('2026-01-03',30,60);
CREATE TABLE $NS.partitioned (
  measured_at date NOT NULL,
  metric text NOT NULL,
  value numeric(8,2) NOT NULL
) PARTITION BY RANGE (measured_at);
CREATE TABLE $NS.measurements_2026_01_01 PARTITION OF $NS.partitioned
  FOR VALUES FROM ('2026-01-01') TO ('2026-01-02');
CREATE TABLE $NS.measurements_2026_01_02 PARTITION OF $NS.partitioned
  FOR VALUES FROM ('2026-01-02') TO ('2026-01-03');
CREATE TABLE $NS.measurements_2026_01_03 PARTITION OF $NS.partitioned
  FOR VALUES FROM ('2026-01-03') TO ('2026-01-04');
INSERT INTO $NS.partitioned SELECT * FROM $NS.narrow;
SELECT 'narrow rows='||(SELECT count(*) FROM $NS.narrow)||
       ' wide rows='||(SELECT count(*) FROM $NS.wide);"
psql_quiet "EXPLAIN (COSTS OFF) SELECT value FROM $NS.partitioned
WHERE measured_at='2026-01-02' AND metric='cpu';" |
  awk '/Scan on/ {for (i=1; i<=NF; i++) if ($i=="on") {print "partition scan: " $(i+1); exit}}'
