resource "shoreline_notebook" "redis_instance_down" {
  name       = "redis_instance_down"
  data       = file("${path.module}/data/redis_instance_down.json")
  depends_on = [shoreline_action.invoke_redis_memory_check,shoreline_action.invoke_redis_setup]
}

resource "shoreline_file" "redis_memory_check" {
  name             = "redis_memory_check"
  input_file       = "${path.module}/data/redis_memory_check.sh"
  md5              = filemd5("${path.module}/data/redis_memory_check.sh")
  description      = "The Redis instance runs out of memory, causing it to crash or become unresponsive"
  destination_path = "/agent/scripts/redis_memory_check.sh"
  resource_query   = "host"
  enabled          = true
}

resource "shoreline_file" "redis_setup" {
  name             = "redis_setup"
  input_file       = "${path.module}/data/redis_setup.sh"
  md5              = filemd5("${path.module}/data/redis_setup.sh")
  description      = "If the Redis instance still cannot be brought back online, consider restoring from a backup or spinning up a new instance."
  destination_path = "/agent/scripts/redis_setup.sh"
  resource_query   = "host"
  enabled          = true
}

resource "shoreline_action" "invoke_redis_memory_check" {
  name        = "invoke_redis_memory_check"
  description = "The Redis instance runs out of memory, causing it to crash or become unresponsive"
  command     = "`chmod +x /agent/scripts/redis_memory_check.sh && /agent/scripts/redis_memory_check.sh`"
  params      = ["REDIS_INSTANCE_NAME"]
  file_deps   = ["redis_memory_check"]
  enabled     = true
  depends_on  = [shoreline_file.redis_memory_check]
}

resource "shoreline_action" "invoke_redis_setup" {
  name        = "invoke_redis_setup"
  description = "If the Redis instance still cannot be brought back online, consider restoring from a backup or spinning up a new instance."
  command     = "`chmod +x /agent/scripts/redis_setup.sh && /agent/scripts/redis_setup.sh`"
  params      = ["REDIS_INSTANCE_NAME"]
  file_deps   = ["redis_setup"]
  enabled     = true
  depends_on  = [shoreline_file.redis_setup]
}

