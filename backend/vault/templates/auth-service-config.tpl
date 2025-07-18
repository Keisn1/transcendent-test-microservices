{{- with secret "secret/auth-service/config" -}}
{
  "jwt_secret": "{{ .Data.data.jwt_secret }}",
  "session_secret": "{{ .Data.data.session_secret }}"
}
{{- end -}}