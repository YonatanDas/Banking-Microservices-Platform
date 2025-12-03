{{- define "common.networkpolicy" -}}
{{- $np := .Values.networkpolicy | default dict }}
{{- if $np.enabled | default false }}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ .Chart.Name }}-network-policy
  labels:
    app: {{ .Chart.Name }}
spec:
  podSelector:
    matchLabels:
      app: {{ .Chart.Name }}

  policyTypes:
    - Ingress
    - Egress

  ingress:
  {{- if eq .Chart.Name "gateway" }}
  - {}
  {{- else }}
  - from:
      - podSelector:
          matchLabels:
            app: gateway
    ports:
      - protocol: TCP
        port: {{ .Values.servicePort }}

  {{- if $np.allowFromServices }}
  {{- range $svc := $np.allowFromServices }}
  - from:
      - podSelector:
          matchLabels:
            app: {{ $svc }}
    ports:
      - protocol: TCP
        port: {{ index $np.targetPorts $svc | default $.Values.containerPort }}
  {{- end }}
  {{- end }}
  {{- end }}

  - from:
      - namespaceSelector:
          matchLabels:
            name: monitoring
    ports:
      - protocol: TCP
        port: {{ .Values.containerPort }}

  egress:
    {{- if $np.allowToServices }}
    {{- range $svc := $np.allowToServices }}
    - to:
        - podSelector:
            matchLabels:
              app: {{ $svc }}
      ports:
        - protocol: TCP
          port: {{ index $np.targetPorts $svc | default $.Values.containerPort }}
    {{- end }}
    {{- end }}

    - to:
        - namespaceSelector:
            matchLabels:
              name: monitoring
      ports:
        - protocol: TCP
          port: 4317  # OTLP gRPC
        - protocol: TCP
          port: 4318  # OTLP HTTP
        - protocol: TCP
          port: 3100  # Loki

    - to:
        - namespaceSelector: {}
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 443
{{- end }}
{{- end }}