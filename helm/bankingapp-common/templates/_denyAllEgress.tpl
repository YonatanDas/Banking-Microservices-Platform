{{- define "common.denyAllEgress" -}}
{{- if .Values.networkpolicy.denyAllEgress }}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ .Chart.Name }}-deny-all-egress
spec:
  podSelector: {}
  policyTypes:
    - Egress
  egress: []
{{- end }}
{{- end }}