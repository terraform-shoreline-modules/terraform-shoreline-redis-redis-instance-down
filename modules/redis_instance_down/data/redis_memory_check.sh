

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