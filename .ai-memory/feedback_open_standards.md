---
name: prefer-open-standards
description: Always use open standards (Agent Skills Spec, agents.md, llms.txt) over proprietary tools like skill.sh/npx skills
type: feedback
---

Use open standards for AI-agent interop instead of proprietary tools.

**Why:** Most LLMs already support these standards natively, so referencing them directly is more portable and doesn't create vendor lock-in (e.g., skill.sh/npx skills was an unnecessary dependency).

**How to apply:** When setting up skills, AGENTS.md, or llms.txt in any project, reference the canonical specs:
- Skills: [Agent Skills Specification](https://agentskills.io/specification)
- AGENTS.md: [agents.md standard](https://agents.md/)
- llms.txt: [llms.txt specification](https://llmstxt.org/)

Point to the repo's own `skills/` folder rather than external install tools.
