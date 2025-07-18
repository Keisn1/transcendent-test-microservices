{{- with secret "secret/user-service/config" -}}
{
  "encryption_key": "{{ .Data.data.encryption_key }}",
  "api_key": "{{ .Data.data.api_key }}"
}
{{- end -}}