---
name: acc-detect-ci-antipatterns
description: Detects CI/CD antipatterns in pipeline configurations. Identifies slow pipelines, security issues, maintenance problems, and provides remediation guidance.
---

# CI Antipattern Detector

Detects common CI/CD antipatterns and provides remediation guidance.

## Antipattern Categories

### 1. Performance Antipatterns

#### Sequential When Parallel Possible

```yaml
# ❌ ANTIPATTERN: Jobs that could run in parallel are sequential
jobs:
  phpstan:
    runs-on: ubuntu-latest
    # ...

  psalm:
    needs: phpstan  # Unnecessary dependency!
    runs-on: ubuntu-latest
    # ...

  phpunit:
    needs: psalm  # Unnecessary dependency!
    runs-on: ubuntu-latest
    # ...
```

```yaml
# ✅ FIX: Run independent jobs in parallel
jobs:
  lint:
    strategy:
      matrix:
        tool: [phpstan, psalm, cs-fixer]
    runs-on: ubuntu-latest
    steps:
      - run: vendor/bin/${{ matrix.tool }}

  phpunit:
    runs-on: ubuntu-latest  # No needs, runs in parallel
    # ...
```

#### Installing Dependencies in Every Job

```yaml
# ❌ ANTIPATTERN: Composer install in every job
jobs:
  phpstan:
    steps:
      - run: composer install
      - run: vendor/bin/phpstan

  phpunit:
    steps:
      - run: composer install  # Duplicate!
      - run: vendor/bin/phpunit
```

```yaml
# ✅ FIX: Install once, share via artifacts
jobs:
  install:
    steps:
      - run: composer install
      - uses: actions/upload-artifact@v4
        with:
          name: vendor
          path: vendor

  phpstan:
    needs: install
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: vendor
      - run: vendor/bin/phpstan
```

#### No Caching

```yaml
# ❌ ANTIPATTERN: No cache configuration
jobs:
  test:
    steps:
      - uses: actions/checkout@v4
      - run: composer install  # Downloads everything every time
```

```yaml
# ✅ FIX: Cache dependencies
jobs:
  test:
    steps:
      - uses: actions/checkout@v4
      - uses: actions/cache@v4
        with:
          path: |
            ~/.composer/cache
            vendor
          key: deps-${{ hashFiles('composer.lock') }}
      - run: composer install
```

### 2. Security Antipatterns

#### Secrets in Logs

```yaml
# ❌ ANTIPATTERN: Secret exposed in logs
- run: |
    echo "Deploying with key: ${{ secrets.DEPLOY_KEY }}"
    curl -H "Authorization: ${{ secrets.API_TOKEN }}" https://api.example.com
```

```yaml
# ✅ FIX: Use environment variables, mask output
- run: |
    echo "Deploying..."
    curl -H "Authorization: Bearer ${API_TOKEN}" https://api.example.com
  env:
    API_TOKEN: ${{ secrets.API_TOKEN }}
```

#### Mutable Action References

```yaml
# ❌ ANTIPATTERN: Using mutable tags
- uses: actions/checkout@main
- uses: actions/setup-php@v2
```

```yaml
# ✅ FIX: Pin to SHA or specific version
- uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11  # v4.1.1
- uses: shivammathur/setup-php@6d7209f44a25a59e904b1ee9f3b0c33ab2cd888d  # v2.27.1
```

#### Overly Permissive Permissions

```yaml
# ❌ ANTIPATTERN: Default permissions (write-all)
name: CI
on: push
jobs:
  build:
    runs-on: ubuntu-latest
```

```yaml
# ✅ FIX: Minimal permissions
name: CI
on: push

permissions:
  contents: read

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write  # Only if needed
```

#### Unsafe pull_request_target

```yaml
# ❌ ANTIPATTERN: Running untrusted code with secrets
on:
  pull_request_target:
jobs:
  build:
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.event.pull_request.head.sha }}  # Untrusted!
      - run: ./scripts/build.sh  # Runs attacker's code with secrets
```

```yaml
# ✅ FIX: Separate trusted and untrusted workflows
# For tests (no secrets needed):
on: pull_request

# For deployments (needs secrets):
on:
  pull_request_target:
jobs:
  build:
    steps:
      - uses: actions/checkout@v4  # Uses base branch (trusted)
```

### 3. Maintenance Antipatterns

#### Duplicated Configuration

```yaml
# ❌ ANTIPATTERN: Copy-pasted steps
jobs:
  test-php82:
    steps:
      - uses: actions/checkout@v4
      - uses: shivammathur/setup-php@v2
        with:
          php-version: '8.2'
      - run: composer install
      - run: vendor/bin/phpunit

  test-php83:
    steps:
      - uses: actions/checkout@v4
      - uses: shivammathur/setup-php@v2
        with:
          php-version: '8.3'  # Only difference!
      - run: composer install
      - run: vendor/bin/phpunit
```

```yaml
# ✅ FIX: Use matrix strategy
jobs:
  test:
    strategy:
      matrix:
        php: ['8.2', '8.3', '8.4']
    steps:
      - uses: actions/checkout@v4
      - uses: shivammathur/setup-php@v2
        with:
          php-version: ${{ matrix.php }}
      - run: composer install
      - run: vendor/bin/phpunit
```

#### Hardcoded Values

```yaml
# ❌ ANTIPATTERN: Hardcoded versions everywhere
- uses: shivammathur/setup-php@v2
  with:
    php-version: '8.4'
# ... later ...
- run: docker build --build-arg PHP_VERSION=8.4
```

```yaml
# ✅ FIX: Centralize in env
env:
  PHP_VERSION: '8.4'

jobs:
  build:
    steps:
      - uses: shivammathur/setup-php@v2
        with:
          php-version: ${{ env.PHP_VERSION }}
      - run: docker build --build-arg PHP_VERSION=${{ env.PHP_VERSION }}
```

#### No Workflow Reuse

```yaml
# ❌ ANTIPATTERN: Same steps in multiple workflows
# ci.yml, deploy.yml, release.yml all have identical test steps
```

```yaml
# ✅ FIX: Reusable workflow
# .github/workflows/test.yml
name: Test
on:
  workflow_call:
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: composer install
      - run: vendor/bin/phpunit

# .github/workflows/ci.yml
name: CI
on: push
jobs:
  test:
    uses: ./.github/workflows/test.yml
```

### 4. Reliability Antipatterns

#### No Timeouts

```yaml
# ❌ ANTIPATTERN: No timeout, can hang forever
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: vendor/bin/phpunit
```

```yaml
# ✅ FIX: Set appropriate timeouts
jobs:
  test:
    runs-on: ubuntu-latest
    timeout-minutes: 30
    steps:
      - run: vendor/bin/phpunit
        timeout-minutes: 20
```

#### No Retry for Flaky Operations

```yaml
# ❌ ANTIPATTERN: Network operations without retry
- run: composer install
```

```yaml
# ✅ FIX: Add retry for flaky operations
jobs:
  install:
    runs-on: ubuntu-latest
    steps:
      - run: composer install
        continue-on-error: true
        id: install
      - run: composer install
        if: steps.install.outcome == 'failure'
```

#### Missing Health Checks

```yaml
# ❌ ANTIPATTERN: No service health check
services:
  mysql:
    image: mysql:8.0
# Tests start immediately, may fail if MySQL not ready
```

```yaml
# ✅ FIX: Add health check
services:
  mysql:
    image: mysql:8.0
    options: >-
      --health-cmd="mysqladmin ping"
      --health-interval=10s
      --health-timeout=5s
      --health-retries=3
```

## Analysis Output Format

```markdown
# CI Antipattern Analysis

**File:** `.github/workflows/ci.yml`
**Total Antipatterns:** 8

## Summary by Category

| Category | Count | Impact |
|----------|-------|--------|
| Performance | 3 | +15 min/build |
| Security | 2 | 🔴 High risk |
| Maintenance | 2 | Technical debt |
| Reliability | 1 | Flaky builds |

## Detected Antipatterns

### PERF-001: Sequential Jobs Could Run Parallel
**Severity:** 🟠 Major
**Impact:** +8 minutes per build
**Location:** Lines 15-45

**Current:**
```yaml
phpstan:
  # ...
psalm:
  needs: phpstan
phpunit:
  needs: psalm
```

**Fix:**
```yaml
phpstan:
  # ...
psalm:
  # No needs - runs in parallel
phpunit:
  needs: [phpstan, psalm]  # Waits for both
```

### SEC-001: Secrets Potentially Exposed
**Severity:** 🔴 Critical
**Location:** Line 67

**Current:**
```yaml
- run: echo "Using ${{ secrets.API_KEY }}"
```

**Fix:**
```yaml
- run: echo "Using API key (masked)"
  env:
    API_KEY: ${{ secrets.API_KEY }}
```

## Estimated Improvements

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Build time | 25 min | 10 min | -60% |
| Security score | C | A | +2 grades |
| Maintainability | Low | High | Significant |

## Remediation Priority

1. **Immediate:** SEC-001, SEC-002 (security issues)
2. **This sprint:** PERF-001, PERF-002 (performance)
3. **Next sprint:** MAINT-001, MAINT-002 (maintenance)
```

## Detection Rules

| ID | Antipattern | Detection |
|----|-------------|-----------|
| PERF-001 | Sequential jobs | `needs` on independent jobs |
| PERF-002 | No caching | Missing `actions/cache` |
| PERF-003 | Duplicate installs | Multiple `composer install` |
| SEC-001 | Secrets in logs | `echo.*secrets\.` |
| SEC-002 | Mutable actions | `uses:.*@(main\|master\|v\d)$` |
| SEC-003 | No permissions | Missing `permissions:` |
| MAINT-001 | Duplicated config | Similar job definitions |
| MAINT-002 | Hardcoded values | Repeated version strings |
| REL-001 | No timeouts | Missing `timeout-minutes` |
| REL-002 | No health checks | Services without `options:` |

## Usage

Provide:
- Path to CI configuration
- Specific categories to focus on (optional)

The detector will:
1. Parse configuration
2. Apply detection rules
3. Calculate impact
4. Generate prioritized fixes
