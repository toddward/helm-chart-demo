{{/*
Common labels
*/}}
{{- define "httpd-demo.labels" -}}
app: {{ .Release.Name }}-httpd
chart: {{ .Chart.Name }}-{{ .Chart.Version }}
managed-by: {{ .Release.Service }}
{{- end }}
