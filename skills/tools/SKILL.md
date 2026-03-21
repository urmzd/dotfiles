---
name: tools
description: Canonical tech stack reference organized by purpose — release, docs/demos, codegen, and per-language tools. Use when choosing libraries, setting up projects, or selecting the right tool.
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash
metadata:
  title: Tools
  category: development
  order: 2
---

# Tools Reference

## Release & Versioning

- **sr** (semantic-release) — AI-powered commits, versioning, changelog, GitHub releases

## Documentation & Demos

- **teasr** — automated screenshot/GIF capture (web, terminal, screen)
- **embed-src** — sync source code into markdown files
- **vhs** — terminal GIF recording with Cyberdream branding

## Code Generation

- **oag** (openapi-generator) — OpenAPI → TypeScript/React/Python clients

## Rust

- **cargo** — build system and package manager
- **clippy** — linting and idiomatic Rust checks
- **clap** — command-line argument parsing
- **cross** — cross-compilation for ARM/musl targets
- **cargo-insta** — snapshot testing

## Go

- **wails** — desktop applications with Go backend and web frontend
- **golangci-lint** — comprehensive Go linting
- **go-rod** — browser automation

## Node

- **ncc** — compile Node.js modules into single files
- **tsdown** — TypeScript bundler (Rolldown-based)
- **biome** — linting and formatting for JS/TS

## Python

- **uv** — package manager and virtual environment tool
- **ruff** — linting and formatting
- **mypy** — static type checking
- **pytest** — testing framework
- **pydantic** — data validation with type annotations
- **fastapi** — async web framework
