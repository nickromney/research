# GitHub Release Version Checker Action

A GitHub Action that checks release versions against configurable expiry policies. This action helps you ensure your dependencies, tools, or infrastructure components stay up-to-date by automatically checking versions against the latest GitHub releases.

This is a TypeScript conversion of the [github-release-version-checker](https://github.com/nickromney-org/github-release-version-checker) Go CLI tool, redesigned specifically for GitHub Actions workflows.

## Features

- **Two Policy Types**:
  - **Days-based**: Time-bound expiry (e.g., must update within 30 days of release)
  - **Version-based**: Semantic versioning windows (e.g., Kubernetes N-3 minor version support)
- **Flexible Configuration**: Customize warning, critical, and expired thresholds
- **Rich Output**: Provides status, version information, and time/version metrics
- **GitHub Actions Integration**: Built-in job summaries and annotations
- **Automatic Token Handling**: Uses `GITHUB_TOKEN` by default

## Usage

### Basic Example

```yaml
name: Check Runner Version
on:
  schedule:
    - cron: '0 0 * * *' # Daily at midnight
  workflow_dispatch:

jobs:
  check-version:
    runs-on: ubuntu-latest
    steps:
      - name: Check GitHub Actions Runner Version
        uses: nickromney/research/github-release-action@v1
        with:
          repository: 'actions/runner'
          current-version: '2.320.0'
          policy-type: 'days'
          days-expired: 30
```

### Days-Based Policy Example

```yaml
- name: Check Version with Days Policy
  uses: nickromney/research/github-release-action@v1
  with:
    repository: 'actions/runner'
    current-version: '2.320.0'
    policy-type: 'days'
    days-warning: 12
    days-critical: 20
    days-expired: 30
    fail-on-expired: true
```

### Version-Based Policy Example

```yaml
- name: Check Kubernetes Version
  uses: nickromney/research/github-release-action@v1
  with:
    repository: 'kubernetes/kubernetes'
    current-version: '1.28.0'
    policy-type: 'version'
    version-window: 3  # N-3 minor versions
    fail-on-expired: true
```

### Check Latest Release Without Current Version

```yaml
- name: Get Latest Release Info
  uses: nickromney/research/github-release-action@v1
  id: check
  with:
    repository: 'nodejs/node'
    policy-type: 'days'

- name: Use Latest Version
  run: |
    echo "Latest version: ${{ steps.check.outputs.latest-version }}"
    echo "Release date: ${{ steps.check.outputs.latest-release-date }}"
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `repository` | GitHub repository to check (format: `owner/repo`) | Yes | - |
| `current-version` | Your current version to check against latest release | No | - |
| `policy-type` | Policy type: `days` or `version` | No | `days` |
| `days-warning` | Days threshold for warning status (days-based policy) | No | `12` |
| `days-critical` | Days threshold for critical status (days-based policy) | No | `20` |
| `days-expired` | Days threshold for expired status (days-based policy) | No | `30` |
| `version-window` | Version window for support (version-based policy, e.g., "3" for N-3) | No | `3` |
| `github-token` | GitHub token for API authentication | No | `${{ github.token }}` |
| `fail-on-expired` | Whether to fail the action if version is expired | No | `true` |

## Outputs

| Output | Description |
|--------|-------------|
| `status` | Version status: `current`, `warning`, `critical`, or `expired` |
| `latest-version` | Latest release version from the repository |
| `latest-release-date` | Date of the latest release (ISO 8601 format) |
| `days-behind` | Number of days behind the latest release |
| `versions-behind` | Number of versions behind the latest release |

## Policy Types

### Days-Based Policy

The days-based policy evaluates version freshness based on the age of the latest release:

- **Current**: Latest release is within warning threshold, or current version matches latest
- **Warning**: Latest release is older than warning threshold but within critical threshold
- **Critical**: Latest release is older than critical threshold but within expired threshold
- **Expired**: Latest release is older than expired threshold

**Use cases:**
- GitHub Actions runners (must update within 30 days)
- Security-sensitive dependencies
- Infrastructure components with time-based compliance requirements

### Version-Based Policy

The version-based policy evaluates based on semantic versioning distance:

- **Current**: Current version matches latest version
- **Warning**: Behind by a few minor versions (≤ half the support window)
- **Critical**: Approaching end of support window (> half but ≤ window)
- **Expired**: Outside the support window (> window)

**Use cases:**
- Kubernetes (N-3 minor version support)
- Node.js (LTS version tracking)
- Any project with semantic versioning support policies

## Examples

### Self-Hosted Runner Compliance

```yaml
name: Check Runner Compliance
on:
  schedule:
    - cron: '0 9 * * 1' # Weekly on Monday at 9am
  workflow_dispatch:

jobs:
  check-runner:
    runs-on: self-hosted
    steps:
      - name: Check Runner Version
        uses: nickromney/research/github-release-action@v1
        with:
          repository: 'actions/runner'
          current-version: ${{ runner.version }}
          policy-type: 'days'
          days-warning: 7
          days-critical: 14
          days-expired: 30
          fail-on-expired: true
```

### Multi-Repository Version Tracking

```yaml
name: Version Audit
on:
  schedule:
    - cron: '0 0 * * 0' # Weekly on Sunday
  workflow_dispatch:

jobs:
  check-versions:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        check:
          - repo: 'kubernetes/kubernetes'
            version: '1.28.0'
            policy: 'version'
          - repo: 'nodejs/node'
            version: '20.10.0'
            policy: 'version'
          - repo: 'docker/docker'
            version: '24.0.0'
            policy: 'days'
    steps:
      - name: Check ${{ matrix.check.repo }}
        uses: nickromney/research/github-release-action@v1
        with:
          repository: ${{ matrix.check.repo }}
          current-version: ${{ matrix.check.version }}
          policy-type: ${{ matrix.check.policy }}
          fail-on-expired: false
```

## Development

This action is part of a research project exploring LLM-assisted code development.

### Building

```bash
cd github-release-action
npm install
npm run build
npm run bundle
```

### Project Structure

```
github-release-action/
├── action.yml          # Action metadata and interface
├── package.json        # Node.js dependencies
├── tsconfig.json       # TypeScript configuration
├── src/
│   ├── main.ts        # Action entry point
│   ├── checker.ts     # GitHub release fetching logic
│   └── policy.ts      # Policy evaluation logic
└── dist/              # Compiled and bundled output
    └── index.js       # Bundled action code
```

## Comparison with Go CLI Tool

This TypeScript action is functionally equivalent to the original Go CLI tool but redesigned for GitHub Actions:

| Feature | Go CLI | TypeScript Action |
|---------|--------|-------------------|
| Release checking | ✅ | ✅ |
| Days-based policy | ✅ | ✅ |
| Version-based policy | ✅ | ✅ |
| Multiple output formats | ✅ (terminal, JSON, CI) | ✅ (GitHub Actions native) |
| Embedded cache | ✅ | ❌ (uses GitHub API) |
| Standalone CLI | ✅ | ❌ (GitHub Actions only) |
| GitHub Actions integration | ⚠️ (via CI mode) | ✅ (native) |

## License

MIT

## Related Projects

- [github-release-version-checker](https://github.com/nickromney-org/github-release-version-checker) - Original Go CLI tool
- [simonw/research](https://github.com/simonw/research) - Research methodology inspiration
