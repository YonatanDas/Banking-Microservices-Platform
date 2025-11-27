{{- define "common.poddisruptionbudget" -}}
{{- if .Values.podDisruptionBudget.enabled }}
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{ .Values.deploymentName }}-pdb
  labels:
    app: {{ .Values.appLabel }}
    app.kubernetes.io/name: {{ .Chart.Name }}
spec:
  {{- if and .Values.podDisruptionBudget.minAvailable .Values.podDisruptionBudget.maxUnavailable }}
  {{- fail "PodDisruptionBudget: Cannot set both minAvailable and maxUnavailable. Set only one." }}
  {{- end }}
  {{- if .Values.podDisruptionBudget.minAvailable }}
  minAvailable: {{ .Values.podDisruptionBudget.minAvailable }}
  {{- else if .Values.podDisruptionBudget.maxUnavailable }}
  maxUnavailable: {{ .Values.podDisruptionBudget.maxUnavailable }}
  {{- else }}
  # Default: ensure at least 1 pod is available during disruptions
  minAvailable: 1
  {{- end }}
  selector:
    matchLabels:
      app: {{ .Values.appLabel }}
{{- end }}
{{- end -}}

