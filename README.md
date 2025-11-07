# research
Research repository for LLM coding agents. Heavily inspired by simonw/research and https://simonwillison.net/2025/Nov/6/async-code-research/

## Projects

### github-release-action (2025-11-07)

A TypeScript GitHub Action that checks GitHub release versions against configurable expiry policies. This is a conversion of the [github-release-version-checker](https://github.com/nickromney-org/github-release-version-checker) Go CLI tool into a reusable GitHub Action for CI/CD workflows.

Features:
- Check if your version is current, approaching expiry, or expired
- Days-based policy (e.g., runners must update within 30 days)
- Version-based policy (e.g., Kubernetes N-3 minor version support)
- Multiple output formats for GitHub Actions
