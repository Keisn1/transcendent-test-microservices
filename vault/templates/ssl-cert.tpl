{{- with secret "pki_int/issue/microservice-role" (printf "common_name=%s.my-microservices.local" (env "SERVICE_NAME")) "ttl=24h" -}}
{{ .Data.certificate }}
{{- end -}}