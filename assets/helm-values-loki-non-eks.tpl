loki:
  # Ring write quorum is floor(replication_factor/2)+1. This deployment runs
  # write.replicas: 2 (see below), and the chart ships replication_factor: 3,
  # which makes the quorum 2 -- so there is no headroom: every rolling restart
  # or node drain takes one ingester out, leaves a single live replica, and
  # writes fail with "at least 2 live replicas required", losing logs.
  #
  # replication_factor: 1 makes the quorum 1, so writes survive one ingester
  # being away. The alternative, write.replicas: 3, does not work on a
  # two-node cluster: the chart applies HARD pod anti-affinity
  # (requiredDuringScheduling, topologyKey kubernetes.io/hostname), so the
  # third pod is unschedulable and the cluster autoscaler would provision an
  # extra node to satisfy it.
  #
  # Trade-off accepted: each log line is held by one ingester rather than
  # replicated. A graceful drain flushes on shutdown and the WAL on the PVC
  # covers restart, so the exposure is an ungraceful loss of an ingester with
  # unflushed chunks. Acceptable for internal observability.
  #
  # KEEP THIS CONSISTENT WITH write.replicas BELOW.
  commonConfig:
    replication_factor: 1
  persistence:
    enabled: true
    storageClassName: ${LOKI_STORAGE_CLASS_NAME}
  auth_enabled: false
  storage:
    type: "s3"
    s3:
      region: ${LOKI_BUCKET_AWS_REGION}
      secretAccessKey: ${LOKI_STORAGE_BUCKET_SECRET_ACCESS_KEY}
      accessKeyId: ${LOKI_STORAGE_BUCKET_ACCESS_KEY_ID}
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
read:
  replicas: 2
write:
  replicas: 2
  persistence:
    storageClass: ${LOKI_STORAGE_CLASS_NAME}
backend:
  replicas: 2
  persistence:
    storageClass: ${LOKI_STORAGE_CLASS_NAME}
global:
  dnsService: coredns

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
