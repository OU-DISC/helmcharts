{{/* Generate basic labels */}}
{{- define "dbvis.labels" }}
deploymentName: {{ .Release.Name | quote }}
{{- end }}

{{- define "nginx.annotations" }}
cert-manager.io/cluster-issuer: letsencrypt-production
{{- end }}

