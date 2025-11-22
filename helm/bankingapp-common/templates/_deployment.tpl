{{- define "common.deployment" -}}
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
      containers:
        - name: {{ .Values.appLabel }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: {{ .Values.containerPort }}

          # ---------- ENV VARS ----------
          env:

            - name: AWS_REGION
              value: {{ .Values.global.aws.region | quote }}

            - name: build.version
              value: {{ .Values.image.tag | default "1.0.0" | quote }}

          {{- if and .Values.secretName }}
            - name: DB_SECRET_NAME
              value: {{ .Values.secretName | quote }}
          {{- end }}

          # ---------- CONFIG + SECRETS ----------
          envFrom:
            - configMapRef:
                name: {{ .Values.configMapName | default "bankingapp-config" }}

          {{- if and .Values.secretName (ne .Values.secretName "") }}
            - secretRef:
                name: {{ .Values.secretName }}
          {{- end }}

          # ---------- HEALTH CHECKS ----------
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
{{- end -}}