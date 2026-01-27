{{/* =========================
   Application name
   ========================= */}}
{{- define "app.name" -}}
{{- required "app.name is required" .Values.app.name -}}
{{- end }}


{{/* =========================
   Release full name
   ========================= */}}
{{- define "app.fullname" -}}
{{ .Release.Name }}
{{- end }}


{{/* =========================
   Default labels
   ========================= */}}
{{- define "app.labels" -}}
app.kubernetes.io/name: {{ include "app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/environment: {{ required "app.environment is required" .Values.app.environment }}
app.kubernetes.io/managed-by: Helm
owner: {{ default "unknown" .Values.labels.owner }}
tier: {{ default "standard" .Values.labels.tier }}
{{- end }}
