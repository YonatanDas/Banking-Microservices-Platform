{{- define "common.servicemonitor" -}}
{{- if .Values.monitoring.enabled }}
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
      path: {{ .Values.monitoring.metricsPath | default "/actuator/prometheus" }}
      interval: {{ .Values.monitoring.scrapeInterval | default "30s" }}
      scrapeTimeout: 10s
{{- end }}
{{- end -}}

