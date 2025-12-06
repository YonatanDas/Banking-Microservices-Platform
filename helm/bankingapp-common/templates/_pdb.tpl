{{- define "common.poddisruptionbudget" -}}
{{- $pdb := .Values.podDisruptionBudget | default dict }}
{{- if $pdb.enabled | default true }}
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{ .Values.deploymentName }}-pdb
  labels:
    app: {{ .Values.appLabel }}
    app.kubernetes.io/name: {{ .Chart.Name }}
spec:
  {{- if and $pdb.minAvailable $pdb.maxUnavailable }}
  {{- fail "PodDisruptionBudget: Cannot set both minAvailable and maxUnavailable. Set only one." }}
  {{- end }}
  {{- if $pdb.minAvailable }}
  minAvailable: {{ $pdb.minAvailable }}
  {{- else if $pdb.maxUnavailable }}
  maxUnavailable: {{ $pdb.maxUnavailable }}
  {{- else }}
  # Default: ensure at least 1 pod is available during disruptions
  minAvailable: 1
  {{- end }}
  selector:
    matchLabels:
      app: {{ .Values.appLabel }}
{{- end }}
{{- end -}}

