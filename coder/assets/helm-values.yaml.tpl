# Rendered by the coder module. Do not edit in the cluster.
coder:
  replicaCount: ${replica_count}

  env:
    - name: CODER_ACCESS_URL
      value: "https://${access_host}"
%{ if wildcard_enabled ~}
    - name: CODER_WILDCARD_ACCESS_URL
      value: "${wildcard_access_host}"
%{ endif ~}
    - name: CODER_PG_CONNECTION_URL
      valueFrom:
        secretKeyRef:
          name: "${database.secret_name}"
          key: "${database.secret_key}"
    - name: CODER_TELEMETRY_ENABLE
      value: "${telemetry_enabled}"
%{ if length(proxy_trusted_origins) > 0 ~}
    - name: CODER_PROXY_TRUSTED_HEADERS
      value: "X-Forwarded-For"
    - name: CODER_PROXY_TRUSTED_ORIGINS
      value: "${join(",", proxy_trusted_origins)}"
%{ endif ~}
%{ if oidc != null ~}
    - name: CODER_OIDC_ISSUER_URL
      value: "${oidc.issuer_url}"
    - name: CODER_OIDC_CLIENT_ID
      value: "${oidc.client_id}"
    - name: CODER_OIDC_CLIENT_SECRET
      valueFrom:
        secretKeyRef:
          name: "${oidc.client_secret_secret_name}"
          key: "${oidc.client_secret_secret_key}"
    - name: CODER_OIDC_SIGN_IN_TEXT
      value: "${oidc.sign_in_text}"
    - name: CODER_OIDC_SCOPES
      value: "${join(",", oidc.scopes)}"
    - name: CODER_OIDC_ALLOW_SIGNUPS
      value: "${oidc.allow_signups}"
    - name: CODER_DISABLE_PASSWORD_AUTH
      value: "${oidc.disable_password_auth}"
%{ if length(oidc.email_domains) > 0 ~}
    - name: CODER_OIDC_EMAIL_DOMAIN
      value: "${join(",", oidc.email_domains)}"
%{ endif ~}
%{ if oidc.icon_url != null ~}
    - name: CODER_OIDC_ICON_URL
      value: "${oidc.icon_url}"
%{ endif ~}
%{ endif ~}
%{ for e in extra_env ~}
    - name: ${e.name}
      value: ${jsonencode(e.value)}
%{ endfor ~}

  resources:
    requests:
      cpu: "${resources.requests.cpu}"
      memory: "${resources.requests.memory}"
    limits:
      cpu: "${resources.limits.cpu}"
      memory: "${resources.limits.memory}"

  # coderd and its built-in provisioner create workspace pods/PVCs via this
  # ServiceAccount. workspacePerms grants a Role in the release namespace;
  # workspaceNamespaces adds the same Role elsewhere.
  serviceAccount:
    workspacePerms: true
    enableDeployments: true
    # The chart's rbac template dereferences `.name` on every entry (its
    # ternary is not lazy), so plain strings fail to render; wrap them.
    workspaceNamespaces: ${jsonencode([for ns in workspace_namespaces : { name = ns }])}

  # TLS terminates at the Gateway; the Service only needs to be reachable
  # from the Envoy proxy pods.
  service:
    type: ClusterIP
    sessionAffinity: None

  ingress:
    enable: false

  # Main hostname on the Gateway's shared wildcard listener; the wildcard
  # hostname (if any) on the ListenerSet's https listener. One HTTPRoute
  # carries both hostnames, Gateway API drops the ones that don't intersect
  # a given parent's listener hostname.
  httproute:
    enable: true
    host: "${access_host}"
%{ if wildcard_enabled ~}
    wildcardHost: "${wildcard_access_host}"
%{ endif ~}
    parentRefs:
      - name: "${gateway.name}"
        namespace: "${gateway.namespace}"
        sectionName: "${gateway.section_name}"
%{ if wildcard_enabled ~}
      - group: gateway.networking.k8s.io
        kind: ListenerSet
        name: "${listenerset_name}"
        sectionName: https
    # Port-80 requests for the wildcard host don't match the Gateway's own
    # redirect route (that one is bound to the Gateway's listeners), so the
    # ListenerSet ships its own.
    httpsRedirect:
      enable: true
      statusCode: 301
      parentRefs:
        - group: gateway.networking.k8s.io
          kind: ListenerSet
          name: "${listenerset_name}"
          sectionName: http
%{ else ~}
    httpsRedirect:
      enable: false
%{ endif ~}

%{ if wildcard_enabled ~}
  # Off-wildcard hostname served by a ListenerSet, not by a bare listener on
  # the shared Gateway (a second cert on the Gateway would trigger
  # OverlappingCertificates and disable HTTP/2 ALPN for every listener).
  # allowedRoutes is omitted on purpose: the Gateway API default
  # (namespaces.from: Same) limits attachment to this namespace.
  listenerset:
    enable: true
    annotations: ${jsonencode(listenerset_annotations)}
    parentRef:
      name: "${gateway.name}"
      namespace: "${gateway.namespace}"
    listeners:
      - name: http
        hostname: "${wildcard_access_host}"
        port: 80
        protocol: HTTP
      - name: https
        hostname: "${wildcard_access_host}"
        port: 443
        protocol: HTTPS
        tls:
          mode: Terminate
          certificateRefs:
            - kind: Secret
              name: "${wildcard_tls_secret_name}"
%{ else ~}
  listenerset:
    enable: false
%{ endif ~}
