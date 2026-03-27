---
name: scaffold-terraform
description: >
  Scaffold a Terraform infrastructure project with CI/CD (plan on PR, apply on push),
  AWS OIDC auth, justfile, .envrc, and standard files. Use when creating infrastructure
  repos, or when the user mentions "new Terraform project", "terraform init", "AWS infra",
  or "infrastructure scaffold".
allowed-tools: Read Grep Glob Bash Edit Write
user-invocable: true
metadata:
  title: Scaffold Terraform Project
  category: development
  order: 14
---

# Scaffold Terraform Project

Generate a production-ready Terraform project following established CI/CD patterns. Read the `scaffold-project` skill first for standard files (README, AGENTS.md, LICENSE, CONTRIBUTING.md, llms.txt).

## When to Use

- Creating a new infrastructure-as-code repository
- Adding CI/CD to an existing Terraform project
- Standardizing a Terraform project to match org conventions

## Generated Files

### `.github/workflows/terraform.yml`

```yaml
name: Terraform

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

concurrency:
  group: terraform-${{ github.ref }}
  cancel-in-progress: false

permissions:
  contents: read
  id-token: write
  pull-requests: write

env:
  AWS_REGION: ${{ secrets.AWS_REGION }}

jobs:
  plan:
    name: Terraform Plan
    runs-on: ubuntu-latest
    outputs:
      has_changes: ${{ steps.plan.outputs.has_changes }}
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: ${{ secrets.AWS_REGION }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.6.0
          terraform_wrapper: false

      - name: Terraform Init
        run: terraform init

      - name: Terraform Format Check
        run: terraform fmt -check
        continue-on-error: true

      - name: Terraform Validate
        run: terraform validate

      - name: Terraform Plan
        id: plan
        run: |
          terraform plan -no-color -out=tfplan -detailed-exitcode 2>&1 | tee plan_output.txt || exit_code=$?
          if [ "${exit_code:-0}" -eq 2 ]; then
            echo "has_changes=true" >> $GITHUB_OUTPUT
          else
            echo "has_changes=false" >> $GITHUB_OUTPUT
          fi
          if [ "${exit_code:-0}" -eq 1 ]; then
            exit 1
          fi

      - name: Upload Plan
        if: github.ref == 'refs/heads/main' && github.event_name == 'push'
        uses: actions/upload-artifact@v4
        with:
          name: tfplan
          path: tfplan
          retention-days: 1

      - name: Comment PR with Plan
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const plan = fs.readFileSync('plan_output.txt', 'utf8');
            const { data: comments } = await github.rest.issues.listComments({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: context.issue.number,
            });
            const botComment = comments.find(comment =>
              comment.user.type === 'Bot' && comment.body.includes('Terraform Plan')
            );
            const truncatedPlan = plan.length > 60000
              ? plan.substring(0, 60000) + '\n\n... (truncated)'
              : plan;
            const body = `## Terraform Plan\n<details>\n<summary>Click to expand plan output</summary>\n\n\`\`\`hcl\n${truncatedPlan}\n\`\`\`\n</details>\n\n**Workflow Run:** [View Details](${context.serverUrl}/${context.repo.owner}/${context.repo.repo}/actions/runs/${context.runId})`;
            if (botComment) {
              await github.rest.issues.updateComment({
                owner: context.repo.owner, repo: context.repo.repo,
                comment_id: botComment.id, body
              });
            } else {
              await github.rest.issues.createComment({
                owner: context.repo.owner, repo: context.repo.repo,
                issue_number: context.issue.number, body
              });
            }

      - name: Plan Summary
        run: |
          echo "## Terraform Plan" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo '```' >> $GITHUB_STEP_SUMMARY
          cat plan_output.txt >> $GITHUB_STEP_SUMMARY
          echo '```' >> $GITHUB_STEP_SUMMARY

  apply:
    name: Terraform Apply
    needs: plan
    if: github.ref == 'refs/heads/main' && github.event_name == 'push' && needs.plan.outputs.has_changes == 'true'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: ${{ secrets.AWS_REGION }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.6.0

      - name: Terraform Init
        run: terraform init

      - name: Download Plan
        uses: actions/download-artifact@v4
        with:
          name: tfplan

      - name: Terraform Apply
        run: terraform apply -auto-approve tfplan

      - name: Terraform Output Summary
        run: |
          echo "## Terraform Apply Complete" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "Infrastructure has been updated successfully." >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "### Outputs" >> $GITHUB_STEP_SUMMARY
          terraform output -no-color >> $GITHUB_STEP_SUMMARY 2>/dev/null || echo "No outputs defined" >> $GITHUB_STEP_SUMMARY
```

No separate `ci.yml` + `release.yml` — Terraform uses a single `terraform.yml` with plan-on-PR and apply-on-push.

### `justfile`

```just
default:
    @just --list

init:
    terraform init

plan:
    terraform plan

apply:
    terraform apply

fmt:
    terraform fmt -recursive

validate:
    terraform validate

check: fmt validate plan

output:
    terraform output
```

### `.envrc`

```sh
use flake .#devops
```

### Project Layout

```
main.tf           # primary resources
variables.tf      # input variables
outputs.tf        # output values
providers.tf      # provider configuration
backend.tf        # state backend (S3)
terraform.tfvars  # variable values (NOT committed if secrets)
```

### Required GitHub Secrets

| Secret | Purpose |
|--------|---------|
| `AWS_ROLE_ARN` | IAM role ARN for OIDC assumption |
| `AWS_REGION` | AWS region (e.g., `us-east-1`) |

## Gotchas

- `cancel-in-progress: false` — never cancel a running Terraform operation
- `terraform_wrapper: false` in plan job to get raw exit codes (exit code 2 = changes detected)
- Plan is saved as artifact and downloaded for apply — ensures apply matches what was planned
- PR comments truncate at 60k chars to stay within GitHub's limits
- OIDC auth (`id-token: write` + `aws-actions/configure-aws-credentials`) — no long-lived AWS keys
- `terraform fmt -check` uses `continue-on-error: true` — warns but doesn't block
- No sr.yaml or semantic release — infrastructure changes are applied directly, not versioned/tagged
- Single concurrency group prevents concurrent applies that could corrupt state
