{{- define "common.denyAllEgress" -}}
{{- if .Values.networkpolicy.denyAllEgress }}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ .Chart.Name }}-deny-all-egress
spec:
<<<<<<< HEAD
  podSelector:
    matchLabels:
      app: {{ .Chart.Name }}
=======
  podSelector: {}
>>>>>>> 4e9b5a8d2e4c6f27ae7a4764892d454536d185fd
  policyTypes:
    - Egress
  egress: []
{{- end }}
{{- end }}