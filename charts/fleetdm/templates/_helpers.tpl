{{/*
Chart name, truncated to the 63-char DNS label limit.
*/}}
{{- define "fleetdm.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Fully qualified app name: <release>-<chart>, or <release> when it already contains the chart name.
*/}}
{{- define "fleetdm.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "fleetdm.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "fleetdm.labels" -}}
helm.sh/chart: {{ include "fleetdm.chart" . }}
{{ include "fleetdm.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{- define "fleetdm.selectorLabels" -}}
app.kubernetes.io/name: {{ include "fleetdm.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Per-component labels. Usage: include "fleetdm.componentLabels" (dict "ctx" $ "component" "mysql")
*/}}
{{- define "fleetdm.componentLabels" -}}
{{ include "fleetdm.labels" .ctx }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{- define "fleetdm.componentSelectorLabels" -}}
{{ include "fleetdm.selectorLabels" .ctx }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{/* Resource names */}}
{{- define "fleetdm.fleet.fullname" -}}
{{- printf "%s-fleet" (include "fleetdm.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "fleetdm.mysql.fullname" -}}
{{- printf "%s-mysql" (include "fleetdm.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "fleetdm.redis.fullname" -}}
{{- printf "%s-redis" (include "fleetdm.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Secret names: an existingSecret wins over the chart-managed one */}}
{{- define "fleetdm.fleet.secretName" -}}
{{- default (include "fleetdm.fleet.fullname" .) .Values.fleet.existingSecret }}
{{- end }}

{{- define "fleetdm.mysql.secretName" -}}
{{- default (include "fleetdm.mysql.fullname" .) .Values.mysql.existingSecret }}
{{- end }}

{{- define "fleetdm.redis.secretName" -}}
{{- default (include "fleetdm.redis.fullname" .) .Values.redis.auth.existingSecret }}
{{- end }}

{{/* In-cluster addresses */}}
{{- define "fleetdm.mysql.address" -}}
{{- printf "%s:3306" (include "fleetdm.mysql.fullname" .) }}
{{- end }}

{{- define "fleetdm.redis.address" -}}
{{- printf "%s:6379" (include "fleetdm.redis.fullname" .) }}
{{- end }}

{{- define "fleetdm.fleet.image" -}}
{{- printf "%s:%s" .Values.fleet.image.repository (default .Chart.AppVersion .Values.fleet.image.tag) }}
{{- end }}

{{/*
Return the existing value of a key in a Secret (already base64-encoded), or a new random alphanumeric value.
Keeps generated credentials stable across upgrades. `helm template`/`--dry-run` have no cluster, so they always generate.
Usage: include "fleetdm.secretValue" (dict "ctx" $ "secret" "name" "key" "mysql-password" "length" 24)
*/}}
{{- define "fleetdm.secretValue" -}}
{{- $existing := lookup "v1" "Secret" .ctx.Release.Namespace .secret }}
{{- if and $existing $existing.data (hasKey $existing.data .key) }}
{{- index $existing.data .key }}
{{- else }}
{{- randAlphaNum (int .length) | b64enc }}
{{- end }}
{{- end }}

{{/* Env vars shared by the prepare-db init container and the Fleet server */}}
{{- define "fleetdm.fleet.env" -}}
- name: FLEET_MYSQL_ADDRESS
  value: {{ include "fleetdm.mysql.address" . | quote }}
- name: FLEET_MYSQL_DATABASE
  value: {{ .Values.mysql.database | quote }}
- name: FLEET_MYSQL_USERNAME
  value: {{ .Values.mysql.username | quote }}
- name: FLEET_MYSQL_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "fleetdm.mysql.secretName" . }}
      key: mysql-password
- name: FLEET_REDIS_ADDRESS
  value: {{ include "fleetdm.redis.address" . | quote }}
{{- if .Values.redis.auth.enabled }}
- name: FLEET_REDIS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "fleetdm.redis.secretName" . }}
      key: redis-password
{{- end }}
- name: FLEET_SERVER_ADDRESS
  value: "0.0.0.0:{{ .Values.fleet.listenPort }}"
- name: FLEET_SERVER_TLS
  value: "false"
- name: FLEET_SERVER_PRIVATE_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "fleetdm.fleet.secretName" . }}
      key: server-private-key
- name: FLEET_LOGGING_JSON
  value: {{ .Values.fleet.logging.json | quote }}
- name: FLEET_LOGGING_DEBUG
  value: {{ .Values.fleet.logging.debug | quote }}
- name: FLEET_LOGGING_DISABLE_BANNER
  value: "true"
- name: FLEET_OSQUERY_STATUS_LOG_PLUGIN
  value: {{ .Values.fleet.osqueryLogPlugin | quote }}
- name: FLEET_OSQUERY_RESULT_LOG_PLUGIN
  value: {{ .Values.fleet.osqueryLogPlugin | quote }}
- name: FLEET_FILESYSTEM_STATUS_LOG_FILE
  value: /tmp/osquery_status
- name: FLEET_FILESYSTEM_RESULT_LOG_FILE
  value: /tmp/osquery_result
- name: FLEET_VULNERABILITIES_DATABASES_PATH
  value: /tmp/vuln
{{- with .Values.fleet.extraEnv }}
{{ toYaml . }}
{{- end }}
{{- end }}
