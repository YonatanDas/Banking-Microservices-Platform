{{- define "common.hpa" -}}
{{- $hpa := .Values.hpa | default dict }}
{{- if $hpa.enabled | default false }}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ .Values.deploymentName }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ .Values.deploymentName }}
  minReplicas: {{ $hpa.minReplicas | default 1 }}
  maxReplicas: {{ $hpa.maxReplicas | default 3 }}
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ $hpa.cpu | default 70 }}
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: {{ $hpa.memory | default 70 }}
{{- end }}
{{- end }}

