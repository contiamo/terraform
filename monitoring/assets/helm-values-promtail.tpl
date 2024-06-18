config:
  # publish data to loki
  clients:
    - url: ${LOKI_ENDPOINT}
      tenant_id: ${TENANT_ID}