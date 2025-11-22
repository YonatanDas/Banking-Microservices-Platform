{{- define "common.denyAllIngress" -}}
{{- if .Values.networkpolicy.denyAllIngress }}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ .Chart.Name }}-deny-all-ingress
spec:
  podSelector: {}
  policyTypes:
    - Ingress
  ingress: []
{{- end }}
{{- end }}