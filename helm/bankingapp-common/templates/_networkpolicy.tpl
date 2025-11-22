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
  # Gateway: Allow traffic from anywhere (ALB/Ingress Controller)
  - {}
  {{- else }}
  # Allow traffic from gateway → this service
  - from:
      - podSelector:
          matchLabels:
            app: gateway
    ports:
      - protocol: TCP
        port: {{ .Values.servicePort }}

  # Allow traffic from sibling microservices
  {{- range $svc := .Values.networkpolicy.allowFromServices }}
  - from:
      - podSelector:
          matchLabels:
            app: {{ $svc }}
    ports:
      - protocol: TCP
        port: {{ index $.Values.networkpolicy.targetPorts $svc }}
  {{- end }}
<<<<<<< HEAD
  {{- end }}

  egress:
    # Allow calling sibling microservices
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
=======
  egress:
    # Allow calling sibling microservices
    - to:
        {{- range .Values.networkpolicy.allowToServices }}
        - podSelector:
            matchLabels:
              app: {{ . }}
        {{- end }}
      ports:
        - protocol: TCP
          port: {{ .Values.servicePort }}
>>>>>>> 4e9b5a8d2e4c6f27ae7a4764892d454536d185fd

    # Allow DNS + external APIs + External Secrets Operator
    - to:
        - namespaceSelector: {}
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 443
{{- end }}
{{- end }}