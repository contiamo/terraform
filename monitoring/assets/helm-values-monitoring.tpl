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
# Disabled alerts:
defaultRules:
  disabled:
    KubeControllerManagerDown: true
    KubeSchedulerDown: true
    KubeMemoryOvercommit: true
    KubeCPUOvercommit: true
    AlertmanagerFailedToSendAlerts: true

alertmanager:
  ingress:
    enabled: true
    ingressClassName: ${ALERT_MANAGER_INGRESS_CLASS_NAME}
    annotations:
      cert-manager.io/cluster-issuer: ${CERT_MANAGER_CLUSTER_ISSUER_NAME}
    hosts:
      - ${ALERT_MANAGER_HOST}
    tls:
    - secretName: ${ALERT_MANAGER_HOST}-tls-auto-generated
      hosts:
      - ${ALERT_MANAGER_HOST}

  config:
    global:
      resolve_timeout: 5m
      slack_api_url: ${ALERT_MANAGER_SLACK_WEBHOOK_URL}
    inhibit_rules:
      - equal:
        - namespace
        - alertname
        source_matchers:
        - severity = critical
        target_matchers:
        - severity =~ warning|info
      - equal:
        - namespace
        - alertname
        source_matchers:
        - severity = warning
        target_matchers:
        - severity = info
      - equal:
        - namespace
        source_matchers:
        - alertname = InfoInhibitor
        target_matchers:
        - severity = info
      - target_matchers:
        - alertname = InfoInhibitor
      # https://runbooks.prometheus-operator.dev/runbooks/kubernetes/cputhrottlinghigh/
      - target_matchers:
        - alertname = CPUThrottlingHigh
      - target_matchers:
        - alertname = AlertmanagerFailedToSendAlerts

    receivers:
    - name: 'cole'
      webhook_configs:
      - url: 'https://cole.prod.contiamo.io/ping/contiamo-eks-cluster'
        send_resolved: false
    - name: "null"
    - name: slack-receiver
      slack_configs:
      - channel: '#alerts'
        send_resolved: true
        text: >-
          {{ range .Alerts -}}
          *Notifying:* <!subteam^S01CGLMNT5G>
          *Description:* {{ .Annotations.message }}
          {{ if .Annotations.runbook_url }} *Runbook Link*: <{{ .Annotations.runbook_url }}|:notebook_with_decorative_cover:>{{ end }}
          {{ if .Annotations.grafana_url }} *Logs in Grafana*: <{{ .Annotations.grafana_url }}/{{ .Annotations.grafana_log_path }}|:chart_with_upwards_trend:>{{ end }}
          *Details:*
            {{ range .Labels.SortedPairs }} • *{{ .Name }}:* `{{ .Value }}`
            {{ end }}
          {{ end }}
        title: '[{{ .Status | toUpper }} {{ if eq .Status "firing" }}:{{ .Alerts.Firing | len }} {{ end }}] {{ .CommonLabels.alertname }}'
    route:
      group_by:
      - alertname
      - cluster
      - service
      group_interval: 5m
      group_wait: 30s
      receiver: slack-receiver
      repeat_interval: 1h
      routes:
      - match:
          alertname: Watchdog
        receiver: "null"
      - match:
          alertname: HeartBeat
        receiver: 'cole'
        group_wait: 0s
        group_interval: 50s
        repeat_interval: 40s
    templates:
    - /etc/alertmanager/template/*.tmpl

additionalPrometheusRulesMap:
- groups:
    - name: blackbox-exporter
      rules:
      - alert: HttpProbeFailed
        annotations:
          description: |-
            Probe failed
              VALUE = {{ $value }}
              LABELS: {{ $labels }}
          message: '{{ $labels.target }} probe failed'
          summary: Probe failed (instance {{ $labels.instance }})
        expr: probe_success == 0
        for: 5m
        labels:
          severity: error
      - alert: SlowProbe
        annotations:
          description: |-
            Blackbox probe took more than 2s to complete
              VALUE = {{ $value }}
              LABELS: {{ $labels }}
          message: '{{ $labels.target }} probe took more than 2s'
          summary: Slow probe (instance {{ $labels.instance }})
        expr: avg_over_time(probe_duration_seconds[1m]) > 2
        for: 5m
        labels:
          severity: warning
      - alert: HttpStatusCode
        annotations:
          description: |-
            HTTP status code is not 200-399
              VALUE = {{ $value }}
              LABELS: {{ $labels }}
          message: '{{ $labels.target }} HTTP status code is not 200-399'
          summary: HTTP Status Code (instance {{ $labels.instance }})
        expr: probe_http_status_code <= 199 OR probe_http_status_code >= 400
        for: 5m
        labels:
          severity: error
      - alert: SslCertExpiresIn15to10Days
        annotations:
          description: |-
            SSL certificate expires in 15 days
              VALUE = {{ $value }}
              LABELS: {{ $labels }}
          message: '{{ $labels.target }} ssl cert expires in 15 to 10 days'
          summary: SSL certificate will expire soon (instance {{ $labels.instance }})
        expr: 86400 * 10 < probe_ssl_earliest_cert_expiry - time() < 86400 * 15
        for: 5m
        labels:
          severity: warning
      - alert: SslCertExpiresIn10to5Days
        annotations:
          description: |-
            SSL certificate expires in 10 days
              VALUE = {{ $value }}
              LABELS: {{ $labels }}
          message: '{{ $labels.target }} ssl cert expires in 10 to 6 days'
          summary: SSL certificate will expire soon (instance {{ $labels.instance }})
        expr: 86400 * 5 < probe_ssl_earliest_cert_expiry - time() < 86400 * 10
        for: 5m
        labels:
          severity: warning
      - alert: SslCertExpiresIn5Days
        annotations:
          description: |-
            SSL certificate expires in 5 days
              VALUE = {{ $value }}
              LABELS: {{ $labels }}
          message: '{{ $labels.target }} ssl cert expires in 5 days'
          summary: SSL certificate will expire soon (instance {{ $labels.instance }})
        expr: 86400 * 5 < probe_ssl_earliest_cert_expiry - time() < 86400 * 6
        for: 5m
        labels:
          severity: warning
      - alert: SslCertExpiresIn4Days
        annotations:
          description: |-
            SSL certificate expires in 4 days
              VALUE = {{ $value }}
              LABELS: {{ $labels }}
          message: '{{ $labels.target }} ssl cert expires in 4 days'
          summary: SSL certificate will expire soon (instance {{ $labels.instance }})
        expr: 86400 * 4 < probe_ssl_earliest_cert_expiry - time() < 86400 * 5
        for: 5m
        labels:
          severity: warning
      - alert: SslCertExpiresIn3Days
        annotations:
          description: |-
            SSL certificate expires in 3 days
              VALUE = {{ $value }}
              LABELS: {{ $labels }}
          message: '{{ $labels.target }} ssl cert expires in 3 days'
          summary: SSL certificate will expire soon (instance {{ $labels.instance }})
        expr: 86400 * 3 < probe_ssl_earliest_cert_expiry - time() < 86400 * 4
        for: 5m
        labels:
          severity: warning
      - alert: SslCertExpiresIn1Days
        annotations:
          description: |-
            SSL certificate expires in 2 days
              VALUE = {{ $value }}
              LABELS: {{ $labels }}
          message: '{{ $labels.target }} ssl cert expires in 2 days'
          summary: SSL certificate will expire soon (instance {{ $labels.instance }})
        expr: 86400 * 2 < probe_ssl_earliest_cert_expiry - time() < 86400 * 3
        for: 5m
        labels:
          severity: warning
      - alert: SslCertExpiresIn1Days
        annotations:
          description: |-
            SSL certificate expires in 1 day
              VALUE = {{ $value }}
              LABELS: {{ $labels }}
          message: '{{ $labels.target }} ssl cert expires in 2 days'
          summary: SSL certificate will expire soon (instance {{ $labels.instance }})
        expr: 86400 * 1 < probe_ssl_earliest_cert_expiry - time() < 86400 * 2
        for: 5m
        labels:
          severity: warning
      - alert: SslCertificateHasExpired
        annotations:
          description: |-
            SSL certificate has expired already
              VALUE = {{ $value }}
              LABELS: {{ $labels }}
          summary: SSL certificate has expired (instance {{ $labels.instance }})
        expr: probe_ssl_earliest_cert_expiry - time()  <= 0
        for: 5m
        labels:
          severity: error
      - alert: SslCertExpiresIn15Days
        annotations:
          description: |-
            SSL certificate expires in 15 days
              VALUE = {{ $value }}
              LABELS: {{ $labels }}
          summary: SSL certificate will expire soon (instance {{ $labels.instance }})
          message: '{{ $labels.target }} ssl cert expires in 15 days'
        expr: probe_ssl_earliest_cert_expiry - time() < 86400 * 15
        for: 5m
        labels:
          severity: critical
      - alert: SslCertificateHasExpired
        annotations:
          description: |-
            SSL certificate has expired already
              VALUE = {{ $value }}
              LABELS: {{ $labels }}
          message: '{{ $labels.target }} SSL certificate expired'
          summary: SSL certificate has expired (instance {{ $labels.instance }})
        expr: probe_ssl_earliest_cert_expiry - time()  <= 0
        for: 5m
        labels:
          severity: error
      - alert: HttpSlowRequests
        annotations:
          description: |-
            HTTP request took more than 2s
              VALUE = {{ $value }}
              LABELS: {{ $labels }}
          message: '{{ $labels.target }} HTTP request took more than 2s'
          summary: HTTP slow requests (instance {{ $labels.instance }})
        expr: avg_over_time(probe_http_duration_seconds[1m]) > 2
        for: 5m
        labels:
          severity: warning
      - alert: SlowPing
        annotations:
          description: |-
            Blackbox ping took more than 2s
              VALUE = {{ $value }}
              LABELS: {{ $labels }}
          message: '{{ $labels.target }} Ping took more than 2s'
          summary: Slow ping (instance {{ $labels.instance }})
        expr: avg_over_time(probe_icmp_duration_seconds[1m]) > 2
        for: 5m
        labels:
          severity: warning
    - name: contiamo-rules
      rules:
      - alert: HeartBeat
        annotations:
          message: "Heartbeat alert from Prometheus. *Notifying:* <!subteam^S01CGLMNT5G>. *Runbook Link*: <https://github.com/contiamo/cole#how-does-it-work|:notebook_with_decorative_cover:>"
          environment: "ENV_SLUG_PLACEHOLDER"
        expr: vector(1)
        labels:
          severity: none
      - alert: KubePodCrashLooping
        annotations:
          grafana_log_path: /explore?orgId=1&left=%5B"now-1h","now","Loki",%7B"expr":"%7Bpod%3D%5C"{{
            $labels.pod }}%5C",namespace%3D%5C"{{ $labels.namespace }}%5C"%7D"%7D,%7B"mode":"Logs"%7D,%7B"ui":%5Btrue,true,true,"none"%5D%7D%5D
          #grafana_url: https://grafana.dev.contiamo.io/
          grafana_url: GRAFANA_URL_PLACEHOLDER
          message: Pod {{ $labels.namespace }}/{{ $labels.pod }} ({{ $labels.container
            }}) is restarting {{ printf "%.2f" $value }} times / 5 minutes.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubepodcrashloopingA
        expr: increase(kube_pod_container_status_restarts_total{job="kube-state-metrics",namespace=~".*"}[5m]) > 0
        for: 5m
        labels:
          severity: critical
      - alert: KubePodNotReady
        annotations:
          message: Pod {{ $labels.namespace }}/{{ $labels.pod }} has been in a non-ready
            state for longer than 15 minutes.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubepodnotready
        expr: sum by (namespace, pod) (max by(namespace, pod) (kube_pod_status_phase{job="kube-state-metrics",
          namespace=~".*", phase=~"Pending|Unknown"}) * on(namespace, pod) group_left(owner_kind)
          max by(namespace, pod, owner_kind) (kube_pod_owner{owner_kind!="Job"})) >
          0
        for: 15m
        labels:
          severity: critical
      - alert: KubeDeploymentGenerationMismatch
        annotations:
          message: Deployment generation for {{ $labels.namespace }}/{{ $labels.deployment
            }} does not match, this indicates that the Deployment has failed but has
            not been rolled back.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubedeploymentgenerationmismatch
        expr: |-
          kube_deployment_status_observed_generation{job="kube-state-metrics", namespace=~".*"}
            !=
          kube_deployment_metadata_generation{job="kube-state-metrics", namespace=~".*"}
        for: 15m
        labels:
          severity: critical
      - alert: KubeDeploymentReplicasMismatch
        annotations:
          message: Deployment {{ $labels.namespace }}/{{ $labels.deployment }} has not
            matched the expected number of replicas for longer than 15 minutes.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubedeploymentreplicasmismatch
        expr: |-
          (
            kube_deployment_spec_replicas{job="kube-state-metrics", namespace=~".*"}
              !=
            kube_deployment_status_replicas_available{job="kube-state-metrics", namespace=~".*"}
          ) and (
            changes(kube_deployment_status_replicas_updated{job="kube-state-metrics", namespace=~".*"}[5m])
              ==
            0
          )
        for: 15m
        labels:
          severity: critical
      - alert: KubeStatefulSetReplicasMismatch
        annotations:
          message: StatefulSet {{ $labels.namespace }}/{{ $labels.statefulset }} has
            not matched the expected number of replicas for longer than 15 minutes.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubestatefulsetreplicasmismatch
        expr: |-
          (
            kube_statefulset_status_replicas_ready{job="kube-state-metrics", namespace=~".*"}
              !=
            kube_statefulset_status_replicas{job="kube-state-metrics", namespace=~".*"}
          ) and (
            changes(kube_statefulset_status_replicas_updated{job="kube-state-metrics", namespace=~".*"}[5m])
              ==
            0
          )
        for: 15m
        labels:
          severity: critical
      - alert: KubeStatefulSetGenerationMismatch
        annotations:
          message: StatefulSet generation for {{ $labels.namespace }}/{{ $labels.statefulset
            }} does not match, this indicates that the StatefulSet has failed but has
            not been rolled back.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubestatefulsetgenerationmismatch
        expr: |-
          kube_statefulset_status_observed_generation{job="kube-state-metrics", namespace=~".*"}
            !=
          kube_statefulset_metadata_generation{job="kube-state-metrics", namespace=~".*"}
        for: 15m
        labels:
          severity: critical
      - alert: KubeStatefulSetUpdateNotRolledOut
        annotations:
          message: StatefulSet {{ $labels.namespace }}/{{ $labels.statefulset }} update
            has not been rolled out.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubestatefulsetupdatenotrolledout
        expr: |-
          max without (revision) (
            kube_statefulset_status_current_revision{job="kube-state-metrics", namespace=~".*"}
              unless
            kube_statefulset_status_update_revision{job="kube-state-metrics", namespace=~".*"}
          )
            *
          (
            kube_statefulset_replicas{job="kube-state-metrics", namespace=~".*"}
              !=
            kube_statefulset_status_replicas_updated{job="kube-state-metrics", namespace=~".*"}
          )
        for: 15m
        labels:
          severity: critical
      - alert: KubeDaemonSetRolloutStuck
        annotations:
          message: Only {{ $value | humanizePercentage }} of the desired Pods of DaemonSet
            {{ $labels.namespace }}/{{ $labels.daemonset }} are scheduled and ready.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubedaemonsetrolloutstuck
        expr: |-
          kube_daemonset_status_number_ready{job="kube-state-metrics", namespace=~".*"}
            /
          kube_daemonset_status_desired_number_scheduled{job="kube-state-metrics", namespace=~".*"} < 1.00
        for: 15m
        labels:
          severity: critical
      - alert: KubeContainerWaiting
        annotations:
          message: Pod {{ $labels.namespace }}/{{ $labels.pod }} container {{ $labels.container}}
            has been in waiting state for longer than 1 hour.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubecontainerwaiting
        expr: sum by (namespace, pod, container) (kube_pod_container_status_waiting_reason{job="kube-state-metrics",
          namespace=~".*"}) > 0
        for: 1h
        labels:
          severity: warning
      - alert: KubeDaemonSetNotScheduled
        annotations:
          message: '{{ $value }} Pods of DaemonSet {{ $labels.namespace }}/{{ $labels.daemonset
            }} are not scheduled.'
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubedaemonsetnotscheduled
        expr: |-
          kube_daemonset_status_desired_number_scheduled{job="kube-state-metrics", namespace=~".*"}
            -
          kube_daemonset_status_current_number_scheduled{job="kube-state-metrics", namespace=~".*"} > 0
        for: 10m
        labels:
          severity: warning
      - alert: KubeDaemonSetMisScheduled
        annotations:
          message: '{{ $value }} Pods of DaemonSet {{ $labels.namespace }}/{{ $labels.daemonset
            }} are running where they are not supposed to run.'
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubedaemonsetmisscheduled
        expr: kube_daemonset_status_number_misscheduled{job="kube-state-metrics", namespace=~".*"}
          > 0
        for: 15m
        labels:
          severity: warning
      - alert: KubeCronJobRunning
        annotations:
          message: CronJob {{ $labels.namespace }}/{{ $labels.cronjob }} is taking more
            than 1h to complete.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubecronjobrunning
        expr: time() - kube_cronjob_next_schedule_time{job="kube-state-metrics", namespace=~".*"}
          > 3600
        for: 1h
        labels:
          severity: warning
      - alert: KubeJobCompletion
        annotations:
          message: Job {{ $labels.namespace }}/{{ $labels.job_name }} is taking more
            than one hour to complete.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubejobcompletion
        expr: kube_job_spec_completions{job="kube-state-metrics", namespace=~".*"} -
          kube_job_status_succeeded{job="kube-state-metrics", namespace=~".*"}  > 0
        for: 1h
        labels:
          severity: warning
      - alert: KubeJobFailed
        annotations:
          message: Job {{ $labels.namespace }}/{{ $labels.job_name }} failed to complete.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubejobfailed
        expr: kube_job_failed{job="kube-state-metrics", namespace=~".*"}  > 0
        for: 15m
        labels:
          severity: warning
      - alert: KubeHpaReplicasMismatch
        annotations:
          message: HPA {{ $labels.namespace }}/{{ $labels.hpa }} has not matched the
            desired number of replicas for longer than 15 minutes.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubehpareplicasmismatch
        expr: |-
          (kube_hpa_status_desired_replicas{job="kube-state-metrics", namespace=~".*"}
            !=
          kube_hpa_status_current_replicas{job="kube-state-metrics", namespace=~".*"})
            and
          changes(kube_hpa_status_current_replicas[15m]) == 0
        for: 15m
        labels:
          severity: warning
      - alert: KubeHpaMaxedOut
        annotations:
          message: HPA {{ $labels.namespace }}/{{ $labels.hpa }} has been running at
            max replicas for longer than 15 minutes.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubehpamaxedout
        expr: |-
          kube_hpa_status_current_replicas{job="kube-state-metrics", namespace=~".*"}
            ==
          kube_hpa_spec_max_replicas{job="kube-state-metrics", namespace=~".*"}
        for: 15m
        labels:
          severity: warning
      - alert: KubeCPUQuotaOvercommit
        annotations:
          message: Cluster has overcommitted CPU resource requests for Namespaces.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubecpuquotaovercommit
        expr: |-
          sum(kube_resourcequota{job="kube-state-metrics", type="hard", resource="cpu"})
            /
          sum(kube_node_status_allocatable_cpu_cores)
            > 1.5
        for: 5m
        labels:
          severity: warning
      - alert: KubeMemoryQuotaOvercommit
        annotations:
          message: Cluster has overcommitted memory resource requests for Namespaces.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubememoryquotaovercommit
        expr: |-
          sum(kube_resourcequota{job="kube-state-metrics", type="hard", resource="memory"})
            /
          sum(kube_node_status_allocatable_memory_bytes{job="node-exporter"})
            > 1.5
        for: 5m
        labels:
          severity: warning
      - alert: KubeQuotaExceeded
        annotations:
          message: Namespace {{ $labels.namespace }} is using {{ $value | humanizePercentage
            }} of its {{ $labels.resource }} quota.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubequotaexceeded
        expr: |-
          kube_resourcequota{job="kube-state-metrics", type="used"}
            / ignoring(instance, job, type)
          (kube_resourcequota{job="kube-state-metrics", type="hard"} > 0)
            > 0.90
        for: 15m
        labels:
          severity: warning
      - alert: NginxError
        annotations:
          message: Ingress {{ $labels.ingress }} non 4**/5** response rate is {{ $value }} over last 1m.
          runbook_url: https://github.com/contiamo/ops-docs/tree/master/runbook
        expr: |-
            sum(rate(nginx_ingress_controller_request_duration_seconds_count{status =~"[4-5].*",}[1m])) > 0.00
        for: 5m
        labels:
          severity: warning
      - alert: NginxErrors
        annotations:
          message: 'Ingress 4-- or 5-- responses over last minute: {{ $value }}.'
          runbook_url: https://github.com/contiamo/ops-docs/tree/master/runbook/NginxIngressMetrics.md#nginxlatency
        expr: sum(rate(nginx_ingress_controller_request_duration_seconds_count{status=~"[4-5].*",}[1m])) by(path, status, ingress, namespace) > 0.00
        for: 1m
        labels:
          severity: warning
      - alert: NginxLatency
        annotations:
          message: Ingress {{ $labels.host }} 95th req. latency percentile {{ $value }}.
          runbook_url: https://github.com/contiamo/ops-docs/tree/master/runbook/NginxIngressMetrics.md#nginxerrors
        expr: histogram_quantile(0.95, sum(rate(nginx_ingress_controller_request_duration_seconds_bucket{ingress!=""}[5m])) by (le, ingress, host, exported_namespace)) > 1
        for: 5m
        labels:
          severity: warning
