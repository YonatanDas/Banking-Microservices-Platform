{{- define "common.deployment" -}}
{{- $monitoring := .Values.monitoring | default dict }}
{{- $otel := $monitoring.otel | default dict }}
{{- $securityContext := .Values.securityContext | default dict }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Values.deploymentName }}
  labels:
    app: {{ .Values.appLabel }}
    app.kubernetes.io/name: {{ .Chart.Name }}
    app.kubernetes.io/version: {{ .Chart.AppVersion }}
    helm.sh/chart: "{{ .Chart.Name }}-{{ .Chart.Version }}"
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Values.appLabel }}
  template:
    metadata:
      labels:
        app: {{ .Values.appLabel }}
    spec:
      serviceAccountName: {{ .Values.serviceAccount.name }}
      
      {{- if $otel.enabled | default false }}
      initContainers:
        - name: download-otel-agent
          image: curlimages/curl:8.5.0
          securityContext:
            runAsNonRoot: {{ $securityContext.runAsNonRoot | default true }}
            runAsUser: {{ $securityContext.runAsUser | default 1000 }}
            allowPrivilegeEscalation: {{ $securityContext.allowPrivilegeEscalation | default false }}
            capabilities:
              drop:
                - ALL
          command:
            - sh
            - -c
            - |
              echo "Downloading OpenTelemetry Java Agent v{{ $otel.agentVersion | default "1.32.0" }}..."
              curl -L -f -o /shared/opentelemetry-javaagent.jar \
                https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v{{ $otel.agentVersion | default "1.32.0" }}/opentelemetry-javaagent.jar
              if [ $? -eq 0 ]; then
                echo "✅ OTEL agent downloaded successfully"
                ls -lh /shared/opentelemetry-javaagent.jar
              else
                echo "❌ Failed to download OTEL agent"
                exit 1
              fi
          volumeMounts:
            - name: otel-agent
              mountPath: /shared
          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              cpu: 200m
              memory: 128Mi
      {{- end }}
      
      containers:
        - name: {{ .Values.appLabel }}
          image: "{{- if .Values.image.repository -}}{{ .Values.image.repository }}{{- else if .Values.global.ecrRegistry -}}{{ .Values.global.ecrRegistry }}/{{ .Values.ecrRepositoryName | default .Values.serviceName | default .Values.appLabel }}{{- else -}}{{ .Values.image.repository }}{{- end }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy | default "IfNotPresent" }}
          securityContext:
            runAsNonRoot: {{ $securityContext.runAsNonRoot | default true }}
            runAsUser: {{ $securityContext.runAsUser | default 1000 }}
            allowPrivilegeEscalation: {{ $securityContext.allowPrivilegeEscalation | default false }}
            capabilities:
              drop:
                - ALL
          ports:
            - containerPort: {{ .Values.containerPort }}

          {{- if $otel.enabled | default false }}
          volumeMounts:
            - name: otel-agent
              mountPath: /app/otel
          {{- end }}

          env:

            - name: AWS_REGION
              value: {{ .Values.global.aws.region | quote }}

            - name: build.version
              value: {{ .Values.image.tag | default "1.0.0" | quote }}

            {{- if and .Values.secretName }}
            - name: DB_SECRET_NAME
              value: {{ .Values.secretName | quote }}
            {{- end }}

            {{- if $otel.enabled | default false }}
            - name: OTEL_SERVICE_NAME
              value: {{ .Values.appLabel | quote }}
            - name: OTEL_EXPORTER_OTLP_ENDPOINT
              value: {{ .Values.global.otelExporterEndpoint | default "http://opentelemetry-collector.monitoring.svc.cluster.local:4317" | quote }}
            - name: OTEL_RESOURCE_ATTRIBUTES
              value: "service.name={{ .Values.appLabel }},deployment.environment={{ .Values.global.environment }}"
            - name: OTEL_METRICS_EXPORTER
              value: {{ .Values.global.otelMetricsExporter | default "otlp" | quote }}
            - name: OTEL_LOGS_EXPORTER
              value: {{ .Values.global.otelLogsExporter | default "none" | quote }}
            - name: JAVA_TOOL_OPTIONS
              value: "-javaagent:/app/otel/opentelemetry-javaagent.jar"
            {{- end }}

          envFrom:
            - configMapRef:
                name: {{ .Values.configMapName | default .Values.global.configMapName | default "platform-config" }}

          {{- if and .Values.secretName (ne .Values.secretName "") }}
            - secretRef:
                name: {{ .Values.secretName }}
          {{- end }}

          livenessProbe:
            httpGet:
              path: {{ .Values.probes.liveness.path }}
              port: {{ .Values.containerPort }}
            initialDelaySeconds: {{ .Values.probes.liveness.initialDelaySeconds }}
            periodSeconds: {{ .Values.probes.liveness.periodSeconds }}
            timeoutSeconds: {{ .Values.probes.liveness.timeoutSeconds }}
            failureThreshold: {{ .Values.probes.liveness.failureThreshold }}

          readinessProbe:
            httpGet:
              path: {{ .Values.probes.readiness.path }}
              port: {{ .Values.containerPort }}
            initialDelaySeconds: {{ .Values.probes.readiness.initialDelaySeconds }}
            periodSeconds: {{ .Values.probes.readiness.periodSeconds }}
            timeoutSeconds: {{ .Values.probes.readiness.timeoutSeconds }}
            failureThreshold: {{ .Values.probes.readiness.failureThreshold }}

          {{- if .Values.resources }}
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
          {{- end }}

      {{- if $otel.enabled | default false }}
      volumes:
        - name: otel-agent
          emptyDir: {}
      {{- end }}
{{- end -}}