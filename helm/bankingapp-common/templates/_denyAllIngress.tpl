{{- define "common.denyAllIngress" -}}
{{- $np := .Values.networkpolicy | default dict }}
{{- if $np.denyAllIngress | default false }}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ .Chart.Name }}-deny-all-ingress
spec:
  podSelector:
    matchLabels:
      app: {{ .Chart.Name }}
  policyTypes:
    - Ingress
  ingress: []
{{- end }}
{{- end }}