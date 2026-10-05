{{- /* Appends each pack's AGENTS.md, in pack order, to a global agent        */}}
{{- /* instruction file. Read at render time, so a freshly pulled pack shows   */}}
{{- /* up on the next `chezmoi apply`.                                        */}}
{{- range (includeTemplate "packs" . | fromJson) }}
{{-   $agents := joinPath .dir "AGENTS.md" }}
{{-   if stat $agents }}

<!-- Pack: {{ .spec }} ({{ $agents }}) -->
{{ include $agents }}
{{-   end }}
{{- end }}