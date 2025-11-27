{{- define "common.networkpolicy" -}}
{{- if .Values.networkpolicy.enabled }}
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

  {{- range $svc := .Values.networkpolicy.allowFromServices }}
  - from:
      - podSelector:
          matchLabels:
            app: {{ $svc }}
    ports:
      - protocol: TCP
        port: {{ index $.Values.networkpolicy.targetPorts $svc }}
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
    {{- if .Values.networkpolicy.allowToServices }}
    {{- range $svc := .Values.networkpolicy.allowToServices }}
    - to:
        - podSelector:
            matchLabels:
              app: {{ $svc }}
      ports:
        - protocol: TCP
          port: {{ index $.Values.networkpolicy.targetPorts $svc }}
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