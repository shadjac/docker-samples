#!/usr/bin/env bash
# Disable THP Support in kernel
echo never > /sys/kernel/mm/transparent_hugepage/enabled
# TCP backlog setting (defaults to 128)
sysctl -w net.core.somaxconn=16384
#-------------------------------------------------------------------------------
exec /usr/bin/redis-server

