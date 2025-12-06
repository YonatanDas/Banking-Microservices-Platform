{{- define "common.service" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.serviceName }}
  labels:
    app: {{ .Values.appLabel }}
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "{{ .Values.containerPort }}"
    prometheus.io/path: "/actuator/prometheus"
spec:
  type: {{ .Values.service.type | default "ClusterIP" }}
  selector:
    app: {{ .Values.appLabel }}
  ports:
    - port: {{ .Values.servicePort }}
      targetPort: {{ .Values.containerPort }}
      protocol: TCP
      name: http
{{- end -}}
