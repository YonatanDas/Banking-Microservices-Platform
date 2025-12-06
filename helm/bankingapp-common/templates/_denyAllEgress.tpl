{{- define "common.denyAllEgress" -}}
{{- $np := .Values.networkpolicy | default dict }}
{{- if $np.denyAllEgress | default false }}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ .Chart.Name }}-deny-all-egress
spec:
  podSelector:
    matchLabels:
      app: {{ .Chart.Name }}
  policyTypes:
    - Egress
  egress: []
{{- end }}
{{- end }}