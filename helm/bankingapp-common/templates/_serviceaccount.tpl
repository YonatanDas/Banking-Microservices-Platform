{{- define "common.serviceaccount" -}}
{{- if .Values.serviceAccount.create }}
{{- $serviceAccount := .Values.serviceAccount | default dict }}
{{- $serviceName := .Values.serviceName | default (trimSuffix "-sa" $serviceAccount.name) }}
{{- $needsRdsAccess := true }}
{{- if hasKey $serviceAccount "needsRdsAccess" }}
{{- $needsRdsAccess = $serviceAccount.needsRdsAccess }}
{{- end }}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ $serviceAccount.name }}
  namespace: {{ .Release.Namespace }}
  {{- if and $serviceAccount.annotations (ne (len $serviceAccount.annotations) 0) }}
  annotations:
    {{- toYaml $serviceAccount.annotations | nindent 4 }}
  {{- else if and .Values.global.awsAccountId .Values.global.environment }}
  {{- if $needsRdsAccess }}
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::{{ .Values.global.awsAccountId }}:role/{{ .Values.global.environment }}-{{ $serviceName }}-rds-access-role"
  {{- end }}
  {{- end }}
{{- end }}
{{- end -}}