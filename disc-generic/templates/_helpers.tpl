{{/* Generate basic labels */}}
{{- define "dbvis.labels" }}
deploymentName: {{ .Release.Name | quote }}
{{- end }}

{{- define "nginx.annotations" }}
cert-manager.io/cluster-issuer: letsencrypt-production
{{- end }}


{{/*
Taken from: https://github.com/bitnami/charts/blob/main/bitnami/common/templates/_tplvalues.tpl
Copyright VMware, Inc.
SPDX-License-Identifier: APACHE-2.0
*/}}


{{/* vim: set filetype=mustache: */}}
{{/*
Renders a value that contains template perhaps with scope if the scope is present.
Usage:
{{ include "common.tplvalues.render" ( dict "value" .Values.path.to.the.Value "context" $ ) }}
{{ include "common.tplvalues.render" ( dict "value" .Values.path.to.the.Value "context" $ "scope" $app ) }}
*/}}
{{- define "common.tplvalues.render" -}}
{{- $value := typeIs "string" .value | ternary .value (.value | toYaml) }}
{{- if contains "{{" (toJson .value) }}
  {{- if .scope }}
      {{- tpl (cat "{{- with $.RelativeScope -}}" $value "{{- end }}") (merge (dict "RelativeScope" .scope) .context) }}
  {{- else }}
    {{- tpl $value .context }}
  {{- end }}
{{- else }}
    {{- $value }}
{{- end }}
{{- end -}}