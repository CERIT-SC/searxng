{{/*
Expand the name of the chart.
*/}}
{{- define "app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Fully qualified app name.
*/}}
{{- define "app.fullname" -}}
{{- printf "%s" (include "app.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels.
*/}}
{{- define "app.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/name: {{ include "app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app: {{ include "app.fullname" . }}
{{- end -}}

{{/*
Selector labels.
*/}}
{{- define "app.selectorLabels" -}}
app: {{ include "app.fullname" . }}
{{- end -}}

{{/*
Name of the Secret holding the MCP auth token.
*/}}
{{- define "app.secretName" -}}
{{- printf "%s-auth" (include "app.fullname" .) -}}
{{- end -}}

{{/*
Resolve the externally-visible hostname.
- FQDN (contains a dot) → used as-is.
- Short host → <host>.<namespace>.dyn.cloud.e-infra.cz
*/}}
{{- define "app.host" -}}
{{- if contains "." .Values.host -}}
{{- .Values.host -}}
{{- else -}}
{{- printf "%s.%s.dyn.cloud.e-infra.cz" .Values.host .Release.Namespace -}}
{{- end -}}
{{- end -}}

{{/*
Container image reference — digest when set, otherwise tag.
*/}}
{{- define "app.image" -}}
{{- if .Values.image.digest -}}
{{- printf "%s@%s" .Values.image.repository .Values.image.digest -}}
{{- else -}}
{{- printf "%s:%s" .Values.image.repository (.Values.image.tag | default .Chart.AppVersion) -}}
{{- end -}}
{{- end -}}
