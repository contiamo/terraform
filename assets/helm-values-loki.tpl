serviceAccount:
  name: ${LOKI_SVC_ACCOUNT_NAME}
  annotations:
    "eks.amazonaws.com/role-arn": ${LOKI_SVC_ACCOUNT_IAM_ROLE_ARN}
loki:
  auth_enabled: false
  storage:
    type: "s3"
    s3:
      region: ${LOKI_BUCKET_AWS_REGION}
    bucketNames:
      chunks: ${LOKI_STORAGE_BUCKET_NAME}
      ruler: ${LOKI_STORAGE_BUCKET_NAME}
      admin: ${LOKI_STORAGE_BUCKET_NAME}
  schemaConfig:
  # Taken from https://grafana.com/docs/loki/latest/operations/storage/schema/ This must be specified for new Loki installs.
    configs:
      - from: 2024-06-17 # for a new install, this must be a date in the past, use a recent date. Format is YYYY-MM-DD.
        object_store: s3
        store: tsdb # tsdb is the current and only recommended value for store.
        schema: v13 # v13 is the most recent schema and recommended value.
        index:
          prefix: index_ # any value without spaces is acceptable.
          period: 24h # must be 24h.
lokiCanary:
  tolerations:
    - key: "karpenter.sh/disrupted"
      operator: "Exists"
      effect: "NoSchedule"

# Cache sizing. The chart's defaults (8192 MB chunks / 1024 MB results) are
# tuned for high-volume deployments; `resources` is set explicitly here because
# leaving it null makes the chart hardcode a 500m CPU request per cache.
# The memory figures are derived by the module from allocatedMemory.
chunksCache:
  allocatedMemory: ${LOKI_CHUNKS_CACHE_ALLOCATED_MEMORY_MB}
  resources:
    requests:
      cpu: ${LOKI_CHUNKS_CACHE_CPU_REQUEST}
      memory: ${LOKI_CHUNKS_CACHE_MEMORY_MI}Mi
    limits:
      memory: ${LOKI_CHUNKS_CACHE_MEMORY_MI}Mi
resultsCache:
  allocatedMemory: ${LOKI_RESULTS_CACHE_ALLOCATED_MEMORY_MB}
  resources:
    requests:
      cpu: ${LOKI_RESULTS_CACHE_CPU_REQUEST}
      memory: ${LOKI_RESULTS_CACHE_MEMORY_MI}Mi
    limits:
      memory: ${LOKI_RESULTS_CACHE_MEMORY_MI}Mi
