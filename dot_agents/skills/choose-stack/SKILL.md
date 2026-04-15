---
name: choose-stack
description: Canonical tech stack reference organized by purpose. Release, docs/demos, codegen, and per-language tools. Use when choosing libraries, setting up projects, or selecting the right tool.
allowed-tools: Read Grep Glob Bash
metadata:
  title: Tools
  category: development
  order: 2
---

# Tools Reference

## Release & Versioning

- **sr** (semantic-release) automated versioning, changelog, GitHub releases, AI-powered commits/rebase/review/PR generation (multi-backend: Claude, Copilot, Gemini)

## Documentation & Demos

- **teasr** automated screenshot/GIF capture (web, terminal, screen)
- **fsrc** sync source code into markdown files

## Code Generation

- **oag** (openapi-generator) OpenAPI → TypeScript/React/Python clients

## Rust

- **cargo** build system and package manager
- **clippy** linting and idiomatic Rust checks
- **clap** command-line argument parsing
- **cross** cross-compilation for ARM/musl targets
- **cargo-insta** snapshot testing

## Go

- **wails** desktop applications with Go backend and web frontend
- **golangci-lint** comprehensive Go linting
- **go-rod** browser automation

## Node

- **ncc** compile Node.js modules into single files
- **tsdown** TypeScript bundler (Rolldown-based)
- **biome** linting and formatting for JS/TS
- **turbo** monorepo build system (task caching, parallel execution)

## Python

- **uv** package manager and virtual environment tool
- **ruff** linting and formatting
- **ty** static type checking
- **pytest** testing framework
- **pydantic** data validation with type annotations
- **fastapi** async web framework
- **logging** (stdlib) foundation layer; prefer over loguru (`logging.getLogger(__name__)`)
- **structlog** structured/JSON logging on top of stdlib; use when services need machine-readable output
- **loguru** quick scripts and one-off CLIs only; never in libraries or production services
- **opentelemetry** tracing, metrics, and log export (otel-sdk + otel-exporter-otlp); stdlib logging has first-class OTel support, structlog works transitively
