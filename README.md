
### About Shoreline
The Shoreline platform provides real-time monitoring, alerting, and incident automation for cloud operations. Use Shoreline to detect, debug, and automate repairs across your entire fleet in seconds with just a few lines of code.

Shoreline Agents are efficient and non-intrusive processes running in the background of all your monitored hosts. Agents act as the secure link between Shoreline and your environment's Resources, providing real-time monitoring and metric collection across your fleet. Agents can execute actions on your behalf -- everything from simple Linux commands to full remediation playbooks -- running simultaneously across all the targeted Resources.

Since Agents are distributed throughout your fleet and monitor your Resources in real time, when an issue occurs Shoreline automatically alerts your team before your operators notice something is wrong. Plus, when you're ready for it, Shoreline can automatically resolve these issues using Alarms, Actions, Bots, and other Shoreline tools that you configure. These objects work in tandem to monitor your fleet and dispatch the appropriate response if something goes wrong -- you can even receive notifications via the fully-customizable Slack integration.

Shoreline Notebooks let you convert your static runbooks into interactive, annotated, sharable web-based documents. Through a combination of Markdown-based notes and Shoreline's expressive Op language, you have one-click access to real-time, per-second debug data and powerful, fleetwide repair commands.

### What are Shoreline Op Packs?
Shoreline Op Packs are open-source collections of Terraform configurations and supporting scripts that use the Shoreline Terraform Provider and the Shoreline Platform to create turnkey incident automations for common operational issues. Each Op Pack comes with smart defaults and works out of the box with minimal setup, while also providing you and your team with the flexibility to customize, automate, codify, and commit your own Op Pack configurations.

# Redis Instance Down
---

This incident type is related to an issue with a Redis instance being down. Redis is an in-memory data structure store used as a database, cache, and message broker. This incident could potentially cause disruption to applications and services that rely on Redis for data storage or caching.

### Parameters
```shell
export REPLICATION_GROUP_ID="PLACEHOLDER"

export CACHE_CLUSTER_IDENTIFIER="PLACEHOLDER"

export PERIOD="PLACEHOLDER"

export CACHE_NODE_ID="PLACEHOLDER"

export CACHE_CLUSTER_ENDPOINT="PLACEHOLDER"

export PORT_NUMBER="PLACEHOLDER"

export REDIS_INSTANCE_NAME="PLACEHOLDER"
```

## Debug

### Check the status of the Redis instance
```shell
aws elasticache describe-replication-groups --replication-group-id ${REPLICATION_GROUP_ID} --show-cache-node-info
```

### Check the logs for any errors or warnings related to the Redis instance
```shell
aws elasticache describe-events --source-type cache-cluster --source-identifier ${CACHE_CLUSTER_IDENTIFIER}
```

### Check the metrics for the Redis instance to identify any spikes or anomalies
```shell
aws cloudwatch get-metric-data --metric-data-queries MetricName=CPUUtilization,Dimensions=[{Name=CacheClusterId,Value=${CACHE_CLUSTER_IDENTIFIER}},{Name=CacheNodeId,Value=${CACHE_NODE_ID}}],StartTime=${START_TIME},EndTime=${END_TIME},Period=${PERIOD},Statistics=[Average] --start-time ${START_TIME} --end-time ${END_TIME}
```

### Check the network connectivity to the Redis instance
```shell
nc -vz ${CACHE_CLUSTER_ENDPOINT} ${PORT_NUMBER}
```

### Check the Redis configuration file for any misconfigurations
```shell
aws elasticache describe-cache-clusters --cache-cluster-id ${CACHE_CLUSTER_IDENTIFIER}
```

### Check the system logs for any issues related to the Redis instance
```shell
dmesg | grep ${CACHE_CLUSTER_IDENTIFIER}
```

### The Redis instance runs out of memory, causing it to crash or become unresponsive
```shell


#!/bin/bash



# Set the instance ID of the Redis instance

INSTANCE_ID=${REDIS_INSTANCE_NAME}



# Get the current memory usage of the instance

MEMORY_USAGE=$(aws cloudwatch get-metric-statistics --namespace AWS/ElastiCache --metric-name FreeableMemory --statistics Average --dimensions Name=CacheClusterId,Value=$INSTANCE_ID Name=CacheNodeId,Value=0001 --start-time $(date -u +%Y-%m-%dT%TZ --date '-5 minutes') --end-time $(date -u +%Y-%m-%dT%TZ) --period 300 | jq '.Datapoints | sort_by(.Timestamp) | last(.).Average')



# Get the maximum memory capacity of the instance

MEMORY_CAPACITY=$(aws elasticache describe-cache-parameters --cache-parameter-group-family redis6.x --max-items 1000 --show-auto-create --query 'CacheParameterList[?ParameterName==`maxmemory-policy`].AllowedValues | [0]' | sed 's/K//')



# Calculate the percentage of memory usage

MEMORY_PERCENTAGE=$(echo "scale=2; $MEMORY_USAGE / $MEMORY_CAPACITY * 100" | bc)



# Check if the memory usage is above 90%

if (( $(echo "$MEMORY_PERCENTAGE > 90" | bc -l) )); then

  echo "Memory usage on Redis instance $INSTANCE_ID is above 90%."

  echo "Please check the instance for any memory leaks, and consider increasing the memory capacity if necessary."

else

  echo "Memory usage on Redis instance $INSTANCE_ID is normal."

fi


```

## Repair

### If the Redis instance still cannot be brought back online, consider restoring from a backup or spinning up a new instance.
```shell


#!/bin/bash



# Set the name of the Redis instance

REDIS_INSTANCE=${REDIS_INSTANCE_NAME}



# Check if the Redis instance is running

redis_status=$(aws elasticache describe-cache-clusters --cache-cluster-id $REDIS_INSTANCE --show-cache-node-info --query CacheClusters[0].CacheNodes[0].CacheNodeStatus)



if [ "$redis_status" == "\"available\"" ]; then

  echo "Redis instance is already running"

else

  # Check if there is a backup available to restore from

  backup_status=$(aws elasticache describe-cache-clusters --cache-cluster-id $REDIS_INSTANCE --show-cache-node-info --query CacheClusters[0].SnapshotRetentionLimit)



  if [ "$backup_status" == "null" ]; then

    # If no backup is available, spin up a new Redis instance

    echo "No backup available, creating new Redis instance"

    aws elasticache create-cache-cluster --cache-cluster-id $REDIS_INSTANCE --engine redis --cache-node-type cache.t2.micro --num-cache-nodes 1 --auto-minor-version-upgrade --snapshot-retention-limit 1 --preferred-maintenance-window sun:05:00-mon:05:30 --tags Key=Environment,Value=Production

  else

    # If a backup is available, restore from the latest backup

    echo "Restoring Redis instance from backup"

    aws elasticache restore-cache-cluster-from-snapshot --cache-cluster-id $REDIS_INSTANCE --snapshot-name $(aws elasticache describe-cache-clusters --cache-cluster-id $REDIS_INSTANCE --show-cache-node-info --query CacheClusters[0].SnapshotRetentionWindow.SnapshotNameList[0])

  fi

fi


```