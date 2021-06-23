#!/bin/bash
miq_hostname=$1
echo `date` "== CONFIGURE UI APPLIANCE [$miq_hostname] FAILOVER : START =="

# Start evm failover monitor
echo `date` "Task : Start evm failover monitor : START"
systemctl start evm-failover-monitor.service
echo `date` "Task : Start evm failover monitor : COMPLETE"