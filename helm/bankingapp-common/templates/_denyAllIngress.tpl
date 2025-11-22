{{- define "common.denyAllIngress" -}}
{{- if .Values.networkpolicy.denyAllIngress }}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ .Chart.Name }}-deny-all-ingress
spec:
<<<<<<< HEAD
  podSelector:
    matchLabels:
      app: {{ .Chart.Name }}
=======
  podSelector: {}
>>>>>>> 4e9b5a8d2e4c6f27ae7a4764892d454536d185fd
  policyTypes:
    - Ingress
  ingress: []
{{- end }}
{{- end }}