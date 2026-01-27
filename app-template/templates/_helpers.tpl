{{- define "app.fullname" -}}
{{ .Release.Name }}
{{- end }}

{{- define "app.labels" -}}
app.kubernetes.io/name: {{ .Values.app.name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/environment: {{ .Values.app.environment }}
app.kubernetes.io/managed-by: Helm
owner: {{ .Values.labels.owner }}
tier: {{ .Values.labels.tier }}
{{- end }}

