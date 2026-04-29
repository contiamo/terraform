global:
  datahub:
    metadata_service_authentication:
      enabled: true

datahub-frontend:
  service:
    type: ClusterIP
  ingress:
    enabled: true
    annotations:
      kubernetes.io/ingress.class: ${INGRESS_CLASS}
    hosts:
      - host: ${UI_INGRESS_HOST}
        paths:
          - "/"
  extraVolumes:
    - name: datahub-default-users
      secret:
        defaultMode: 0444
        secretName: datahub-default-users
  extraVolumeMounts:
    - name: datahub-default-users
      # path specified in the docs
      # https://datahubproject.io/docs/authentication/guides/add-users#changing-the-default-datahub-user
      mountPath: /datahub-frontend/conf/user.props
      subPath: user.props

datahub-gms:
  service:
    type: ClusterIP
  ingress:
    enabled: true
    annotations:
      kubernetes.io/ingress.class: ${INGRESS_CLASS}
    hosts:
      - host: ${API_INGRESS_HOST}
        paths:
          - "/"
