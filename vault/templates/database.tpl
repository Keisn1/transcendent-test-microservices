{{- with secret "secret/database" -}}
{
  "username": "{{ .Data.data.username }}",
  "password": "{{ .Data.data.password }}",
  "host": "{{ .Data.data.host }}",
  "port": {{ .Data.data.port }},
  "database": "{{ .Data.data.database }}"
}
{{- end -}}