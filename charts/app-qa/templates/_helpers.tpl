{{/*----- labels 模板，通用給 deployment service 確保一致性 -----*/}}
{{- define "labels" }}
{{- with .Values.labels }}
env: {{ .env }}
type: {{ .type }}
dept: {{ .dept }}
product: {{ .product }}
repo: {{ .repo }}
{{- if .tag }}
tag: {{ .tag }}
{{- end }}
{{- end }}
{{- end }}

{{/*------------- containerPorts -----------*/}}
{{- define "containerPorts" }}
{{- range .ports }}
- name: {{ .name }}
  containerPort: {{ .containerPort }}
{{- end }}
{{- end }}

{{/*----- container resources ------*/}}
{{- define "resources" }}
{{- with .Values.resources }}
{{- if .limits }}
limits:
  cpu: {{ .limits.cpu }}
  memory: {{ .limits.memory }}
{{- end }}
{{- if .requests }}
requests:
  cpu: {{ .requests.cpu }}
  memory: {{ .requests.memory }}
{{- end }}
{{- end }}
{{- end }}

{{/*----- service ports ------*/}}
{{- define "servicePorts" }}
{{- if eq .type "NodePort" }}
  # NodePort 類型，可以指定 nodePort
  {{- range .ports }}
  - name: {{ .name }}
    port: {{ .port }}
    protocol: "TCP"
    {{- if .targetPort }}
    targetPort: {{ .targetPort }}
    {{- end }}
    {{- if .nodePort }}
    nodePort: {{ .nodePort }}
    {{- end }}
  {{- end }}
{{- else }}
  # ClusterIP 類型
  {{- range .ports }}
  - name: {{ .name }}
    port: {{ .port }}
    protocol: "TCP"
    {{- if .targetPort }}
    targetPort: {{ .targetPort }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}

{{/*----- env 模板 -----*/}}
{{- define "env" }}
{{- range .env }}
- name: {{ .name }}
  value: {{ .value | quote }}
{{- end }}
{{- end }}

{{/*----- 通用 env ------*/}}
{{- define "common-env" }}
- name: REPO_NAME
  valueFrom:
    fieldRef:
      fieldPath: metadata.labels['repo']
- name: PRODUCT_NAME
  valueFrom:
    fieldRef:
      fieldPath: metadata.labels['product']
- name: NAMESPACE_NAME
  valueFrom:
    fieldRef:
      fieldPath: metadata.namespace
{{- end }}

{{/*------ accessModes => pv & pvc -------*/}}
{{- define "accessModes" }}
{{- if .accessModes }}
{{- range .accessModes }}
- {{ . }}
{{- end }}
{{- else }}
- ReadWriteOnce
{{- end }}
{{- end }}

{{/*----- configmap checksum/config -----*/}}
{{- define "checksum" }}
checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
{{- end }}


{{/*----- livenessProbe -------*/}}
{{- define "livenessProbe" }}
{{- if .livenessProbe.tcpSocket }}
tcpSocket:
  port: {{ .livenessProbe.tcpSocket.port }}
{{- else if .livenessProbe.command }}
exec:
  command:
  {{- range .livenessProbe.command }}
    - {{ . }}
  {{- end }}
{{- else if .livenessProbe.httpGet }}
httpGet:
  path: {{ .livenessProbe.httpGet.path }}
  port: {{ .livenessProbe.httpGet.port }}
  {{- if .livenessProbe.httpGet.scheme | default "HTTP" }}
  scheme: {{ .livenessProbe.httpGet.scheme }}
  {{- end }}
  {{- if .livenessProbe.httpGet.httpHeaders }}
  httpHeaders:
  {{- range .livenessProbe.httpGet.httpHeaders }}
    - name: {{ .name }}
      value: {{ .value }}
  {{- end }}
  {{- end }}
{{- end }}  
# 容器啟動後要等待多少秒後才啟動探针
initialDelaySeconds: {{ .livenessProbe.initialDelaySeconds | default 0 }}
# 探測時間間隔
periodSeconds: {{ .livenessProbe.periodSeconds | default 10 }}
# 探測超時等待時間
timeoutSeconds: {{ .livenessProbe.timeoutSeconds | default 1 }}
# 視為成功的最小連續成功數
successThreshold: {{ .livenessProbe.successThreshold | default 1 }}
# 視為失敗的最小連續失敗數
failureThreshold: {{ .livenessProbe.failureThreshold | default 3 }}
{{- end }}

{{/*----- readinessProbe ------*/}}
{{- define "readinessProbe" }}
{{- if .readinessProbe.tcpSocket }}
tcpSocket:
  port: {{ .readinessProbe.tcpSocket.port }}
{{- else if .readinessProbe.command }}
exec:
  command:
  {{- range .readinessProbe.command }}
    - {{ . }}
  {{- end }}
{{- else if .readinessProbe.httpGet }}
httpGet:
  path: {{ .readinessProbe.httpGet.path }}
  port: {{ .readinessProbe.httpGet.port }}
  {{- if .readinessProbe.httpGet.scheme }}
  scheme: {{ .readinessProbe.httpGet.scheme | default "HTTP" }}
  {{- end }}
  {{- if .readinessProbe.httpGet.httpHeaders }}
  httpHeaders:
  {{- range .readinessProbe.httpGet.httpHeaders }}
    - name: {{ .name }}
      value: {{ .value }}
  {{- end }}
  {{- end }}
{{- end }}  
# 容器啟動後要等待多少秒後才啟動探针
initialDelaySeconds: {{ .readinessProbe.initialDelaySeconds | default 0 }}
# 探測時間間隔
periodSeconds: {{ .readinessProbe.periodSeconds | default 10 }}
# 探測超時等待時間
timeoutSeconds: {{ .readinessProbe.timeoutSeconds | default 1 }}
# 視為成功的最小連續成功數
successThreshold: {{ .readinessProbe.successThreshold | default 1 }}
# 視為失敗的最小連續失敗數
failureThreshold: {{ .readinessProbe.failureThreshold | default 3 }}
{{- end }}

{{/*----------- hpa metrics -----------*/}}
{{- define "metrics" }}
{{- range .metrics }}
- type: Resource
  resource:
    name: {{ .resource.name | default "cpu" }}
    target:
      {{- if eq .resource.type "Utilization" }}
      type: Utilization
      averageUtilization: {{ .resource.value | default 80 }}
      {{- else if eq .resource.type "AverageValue" }}
      type: AverageValue
      averageValue: {{ .resource.value | default "1" }}
      {{- end }}
{{- end }}
{{- end }}

{{/*----------- configmap -----------*/}}
{{- define "configmap" }}
{{- with .Values.deployment.container.envs }}
{{- if .ref }}
- configMapRef:
    name: {{ .ref.configMapRefName }}
- secretRef:
    name: {{ .ref.secretRefName }}
{{- end }}
{{- end }}
{{- end }}

{{/*----------- secret -----------*/}}
{{- define "secret" }}
{{- with .Values.deployment.container.envs }}
{{- if .secretFrom }}
- name: {{ .secretFrom.envName }}
  valueFrom:
    secretKeyRef:
      name: {{ .secretFrom.secretKeyRefName }}
      key: {{ .secretFrom.secretKeyRefKey }}
{{- end }}
{{- end }}
{{- end }}

{{/*----------- volumeMounts -----------*/}}
{{- define "volumeMounts" }}
{{- with .Values.deployment.container }}
{{- if .volumeMounts }}
- name: {{ .volumeMounts.name }}
  mountPath: {{ .volumeMounts.mountPath }}
{{- end }}
{{- end }}
{{- end }}

{{/*----------- volumes -----------*/}}
{{- define "volumes" }}
{{- with .Values.deployment.container.volumes }}
- name: {{ .name }}
  {{- if .configMap }}
  configMap:
    name: {{ .configMap.name }}
    items:
      - key: {{ .configMap.itemsKey }}
        path: {{ .configMap.itemsPath }}
  {{- else }}
  emptyDir: {}
  {{- end }}
{{- end }}
{{- end }}
