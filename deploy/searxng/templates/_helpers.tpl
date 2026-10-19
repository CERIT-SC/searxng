{{/*
Expand the name of the chart.
*/}}
{{- define "searxng.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "searxng.fullname" -}}
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

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "searxng.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "searxng.labels" -}}
helm.sh/chart: {{ include "searxng.chart" . }}
{{ include "searxng.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "searxng.selectorLabels" -}}
app.kubernetes.io/name: {{ include "searxng.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Resolve the externally-visible hostname.
- FQDN (contains a dot) -> used as-is.
- Short host -> <host>.<namespace>.dyn.cloud.e-infra.cz
*/}}
{{- define "searxng.host" -}}
{{- if contains "." .Values.host -}}
{{- .Values.host -}}
{{- else -}}
{{- printf "%s.%s.dyn.cloud.e-infra.cz" .Values.host .Release.Namespace -}}
{{- end -}}
{{- end -}}

{{/*
Resolve the SearXNG base URL.
*/}}
{{- define "searxng.baseUrl" -}}
{{- if .Values.searxng.baseUrl -}}
{{- .Values.searxng.baseUrl -}}
{{- else -}}
{{- printf "https://%s/" (include "searxng.host" .) -}}
{{- end -}}
{{- end -}}
