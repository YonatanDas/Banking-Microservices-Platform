{{- define "common.serviceaccount" -}}
{{- if .Values.serviceAccount.create }}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ .Values.serviceAccount.name }}
  namespace: {{ .Release.Namespace }}
  {{- if and .Values.serviceAccount.annotations (ne (len .Values.serviceAccount.annotations) 0) }}
  annotations:
    {{- toYaml .Values.serviceAccount.annotations | nindent 4 }}
  {{- end }}
{{- end }}
{{- end -}}