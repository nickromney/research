# GitHub Actions Workflow

This directory contains the GitHub Actions workflow for automated testing of the mock-api-lab.

## Installation

Due to GitHub permissions, the workflow file needs to be manually added to the repository after the PR is merged.

### Steps to Add Workflow

1. **Copy the workflow file**:
   ```bash
   mkdir -p .github/workflows
   cp mock-api-lab/docs/github-workflow.yml .github/workflows/mock-api-lab.yml
   ```

2. **Commit and push**:
   ```bash
   git add .github/workflows/mock-api-lab.yml
   git commit -m "Add GitHub Actions workflow for mock-api-lab"
   git push
   ```

## Workflow Features

The workflow (`github-workflow.yml` in this directory) includes:

- **Triggers**:
  - Manual trigger with `workflow_dispatch`
  - Automatic on push to `mock-api-lab/**`
  - Automatic on PR affecting `mock-api-lab/**`

- **Testing**:
  - Multi-version Node.js (18.x, 20.x)
  - Automated service startup
  - Health checks
  - OAuth 2.0 flow validation
  - APIM subscription key testing
  - Rate limiting verification
  - Full test suite execution

- **Artifacts**:
  - Test results uploaded for review
  - Retention: 7 days

## Manual Trigger

Once the workflow is installed, you can run it manually:

1. Go to **Actions** tab in GitHub
2. Select **Mock API Lab CI**
3. Click **Run workflow**
4. Choose branch and optionally enable demo mode

## Workflow File Location

The complete workflow file is available at:
```
mock-api-lab/docs/github-workflow.yml
```

Copy this to:
```
.github/workflows/mock-api-lab.yml
```

## Why Manual Installation?

GitHub Apps (including Claude Code) require special `workflows` permission to create or modify workflow files. This is a security feature to prevent unauthorized workflow modifications.

## Testing Without GitHub Actions

You can test locally without GitHub Actions:

```bash
cd mock-api-lab
./install.sh
npm run start:all

# In another terminal
cd scripts
./test-api.sh
./load-test.sh
```

## Status Badge

After installing the workflow, you can add a status badge to the README:

```markdown
![Mock API Lab CI](https://github.com/nickromney/research/workflows/Mock%20API%20Lab%20CI/badge.svg)
```
