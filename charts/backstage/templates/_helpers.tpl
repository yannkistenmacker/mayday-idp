{{- define "backstage.labels" -}}
app: backstage
app.kubernetes.io/name: backstage
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end -}}

{{- define "backstage.selectorLabels" -}}
app: backstage
{{- end -}}
