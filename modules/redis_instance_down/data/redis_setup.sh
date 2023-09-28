

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