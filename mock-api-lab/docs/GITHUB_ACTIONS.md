# GitHub Actions Workflow

The Mock API Lab includes a comprehensive GitHub Actions workflow for automated testing.

## Status

✅ **Workflow Installed**: `.github/workflows/mock-api-lab.yml`
✅ **Triggers**: Push to `mock-api-lab/**`, PRs, and manual dispatch
✅ **Tests**: 12 automated tests across OAuth and APIM components
✅ **Node.js Versions**: 18.x and 20.x

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

The workflow is installed at:
```
.github/workflows/mock-api-lab.yml
```

A reference copy is also available at:
```
mock-api-lab/docs/github-workflow.yml
```

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
