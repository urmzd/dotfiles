{{- /* Appends the work pack's AGENTS.md to a global agent instruction file.   */}}
{{- /* Read at render time, so a freshly pulled work pack shows up on the next */}}
{{- /* `chezmoi apply`.                                                         */}}
{{- $work_agents := joinPath .chezmoi.homeDir ".config/work/AGENTS.md" -}}
{{- if stat $work_agents }}

<!-- Work pack: ~/.config/work/AGENTS.md -->
{{ include $work_agents }}
{{- end }}