{{- define "common.servicemonitor" -}}
{{- $monitoring := .Values.monitoring | default dict }}
{{- if $monitoring.enabled | default false }}
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: {{ .Values.appLabel }}-servicemonitor
  labels:
    app: {{ .Values.appLabel }}
    release: prometheus-operator-dev
spec:
  selector:
    matchLabels:
      app: {{ .Values.appLabel }}
  endpoints:
    - port: http
      path: {{ $monitoring.metricsPath | default "/actuator/prometheus" }}
      interval: {{ $monitoring.scrapeInterval | default "30s" }}
      scrapeTimeout: 10s
{{- end }}
{{- end -}}

