#!/bin/bash

echo "test-postgres-cluster.service.postgres.cluster.test:5432:testdb:repmgr:DUMMYPASSWORD1337" >> ~/.pgpass

psql -h test-postgres-cluster.service.postgres.cluster.test -p 5432 -d postgres -U repmgr -c "create database testdb;"
psql -h test-postgres-cluster.service.postgres.cluster.test -p 5432 -d testdb -U repmgr -c "create table a (a int);"

PGCONNECT_TIMEOUT=5 watch -n 5 'psql -h test-postgres-cluster.service.postgres.cluster.test -p 5432 -d testdb -U repmgr -c "insert into a values (10); select * from a;" || echo "No connection..."'
