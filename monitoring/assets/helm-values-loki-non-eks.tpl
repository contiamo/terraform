loki:
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
