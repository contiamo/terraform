coreDns:
  enabled: true
kubeDns:
  enabled: false

grafana:
  adminUser: ${GRAFANA_ADMIN_USER}
  adminPassword: ${GRAFANA_ADMIN_PASSWORD}
  persistence:
    type: pvc
    enabled: false
    accessModes:
      - ReadWriteOnce
    size: ${GRAFANA_PVC_SIZE}
  ingress:
    enabled: true
    ingressClassName: ${GRAFANA_INGRESS_CLASS_NAME}
    annotations:
      cert-manager.io/cluster-issuer: ${CERT_MANAGER_CLUSTER_ISSUER_NAME}
    hosts:
      - ${GRAFANA_HOST}
    tls:
     - secretName: ${GRAFANA_HOST}-tls-auto-generated
       hosts:
         - ${GRAFANA_HOST}
  resources:
   limits:
     cpu: 100m
     memory: 128Mi
   requests:
     cpu: 100m
     memory: 128Mi
