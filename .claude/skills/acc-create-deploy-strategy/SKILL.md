---
name: acc-create-deploy-strategy
description: Generates deployment strategy configurations. Creates blue-green, canary, rolling deployment configs for GitHub Actions and GitLab CI with health checks and rollback procedures.
---

# Deployment Strategy Generator

Generates deployment configurations for zero-downtime deployments.

## Blue-Green Deployment

### GitHub Actions

```yaml
# .github/workflows/deploy-blue-green.yml
name: Blue-Green Deploy

on:
  push:
    tags: ['v*']
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment'
        required: true
        type: choice
        options: [staging, production]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      image_tag: ${{ steps.meta.outputs.tags }}
    steps:
      - uses: actions/checkout@v4

      - name: Build and push image
        uses: docker/build-push-action@v5
        with:
          push: true
          tags: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: ${{ github.event.inputs.environment || 'production' }}
      url: ${{ steps.deploy.outputs.url }}
    steps:
      - uses: actions/checkout@v4

      - name: Determine target environment
        id: env
        run: |
          ACTIVE=$(curl -s https://api.example.com/active-env)
          if [ "$ACTIVE" = "blue" ]; then
            echo "target=green" >> $GITHUB_OUTPUT
            echo "url=https://green.example.com" >> $GITHUB_OUTPUT
          else
            echo "target=blue" >> $GITHUB_OUTPUT
            echo "url=https://blue.example.com" >> $GITHUB_OUTPUT
          fi

      - name: Deploy to inactive environment
        id: deploy
        env:
          TARGET: ${{ steps.env.outputs.target }}
          IMAGE: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
        run: |
          # Deploy to target environment
          ssh deploy@${{ secrets.DEPLOY_HOST }} << EOF
            docker pull $IMAGE
            docker-compose -f docker-compose.$TARGET.yml up -d
          EOF
          echo "url=${{ steps.env.outputs.url }}" >> $GITHUB_OUTPUT

      - name: Health check
        run: |
          for i in {1..30}; do
            if curl -sf "${{ steps.env.outputs.url }}/health"; then
              echo "Health check passed"
              exit 0
            fi
            sleep 10
          done
          echo "Health check failed"
          exit 1

      - name: Run smoke tests
        run: |
          npm run test:smoke -- --base-url="${{ steps.env.outputs.url }}"

      - name: Switch traffic
        if: success()
        run: |
          curl -X POST https://api.example.com/switch-traffic \
            -H "Authorization: Bearer ${{ secrets.DEPLOY_TOKEN }}" \
            -d '{"target": "${{ steps.env.outputs.target }}"}'

      - name: Rollback on failure
        if: failure()
        run: |
          echo "Deployment failed, keeping traffic on current environment"
          curl -X POST https://api.example.com/rollback \
            -H "Authorization: Bearer ${{ secrets.DEPLOY_TOKEN }}"
```

### GitLab CI

```yaml
# .gitlab-ci.yml - Blue-Green
stages:
  - build
  - deploy
  - switch
  - rollback

variables:
  REGISTRY: $CI_REGISTRY_IMAGE

build:
  stage: build
  image: docker:24
  services:
    - docker:24-dind
  script:
    - docker build -t $REGISTRY:$CI_COMMIT_SHA .
    - docker push $REGISTRY:$CI_COMMIT_SHA

.deploy_template: &deploy_template
  stage: deploy
  image: alpine:latest
  before_script:
    - apk add --no-cache curl openssh-client
  script:
    - |
      ssh deploy@$DEPLOY_HOST << EOF
        docker pull $REGISTRY:$CI_COMMIT_SHA
        docker-compose -f docker-compose.$TARGET_ENV.yml up -d
      EOF
    - |
      for i in $(seq 1 30); do
        curl -sf "https://$TARGET_ENV.example.com/health" && exit 0
        sleep 10
      done
      exit 1

deploy:blue:
  <<: *deploy_template
  variables:
    TARGET_ENV: blue
  rules:
    - if: $DEPLOY_TARGET == "blue"

deploy:green:
  <<: *deploy_template
  variables:
    TARGET_ENV: green
  rules:
    - if: $DEPLOY_TARGET == "green"

switch:traffic:
  stage: switch
  image: alpine:latest
  script:
    - |
      curl -X POST https://api.example.com/switch-traffic \
        -H "Authorization: Bearer $DEPLOY_TOKEN" \
        -d "{\"target\": \"$DEPLOY_TARGET\"}"
  when: manual
  needs: [deploy:blue, deploy:green]

rollback:
  stage: rollback
  image: alpine:latest
  script:
    - |
      curl -X POST https://api.example.com/rollback \
        -H "Authorization: Bearer $DEPLOY_TOKEN"
  when: manual
```

## Canary Deployment

### GitHub Actions

```yaml
# .github/workflows/deploy-canary.yml
name: Canary Deploy

on:
  push:
    branches: [main]

jobs:
  deploy-canary:
    runs-on: ubuntu-latest
    environment: canary
    steps:
      - uses: actions/checkout@v4

      - name: Deploy canary (5%)
        id: canary
        run: |
          # Deploy to canary instances
          kubectl set image deployment/app app=$IMAGE --namespace=canary
          kubectl rollout status deployment/app --namespace=canary

      - name: Configure traffic split (5%)
        run: |
          kubectl apply -f - <<EOF
          apiVersion: split.smi-spec.io/v1alpha1
          kind: TrafficSplit
          metadata:
            name: app-canary
          spec:
            service: app
            backends:
            - service: app-stable
              weight: 95
            - service: app-canary
              weight: 5
          EOF

      - name: Monitor canary (10 minutes)
        id: monitor
        run: |
          END=$(($(date +%s) + 600))
          while [ $(date +%s) -lt $END ]; do
            ERROR_RATE=$(curl -s "http://prometheus:9090/api/v1/query?query=rate(http_requests_total{status=~'5..'}[1m])" | jq '.data.result[0].value[1]')
            if (( $(echo "$ERROR_RATE > 0.01" | bc -l) )); then
              echo "Error rate too high: $ERROR_RATE"
              echo "rollback=true" >> $GITHUB_OUTPUT
              exit 1
            fi
            sleep 30
          done
          echo "Canary healthy"

      - name: Promote canary (25%)
        if: success()
        run: |
          kubectl apply -f - <<EOF
          apiVersion: split.smi-spec.io/v1alpha1
          kind: TrafficSplit
          metadata:
            name: app-canary
          spec:
            service: app
            backends:
            - service: app-stable
              weight: 75
            - service: app-canary
              weight: 25
          EOF

      - name: Monitor promotion (15 minutes)
        run: |
          sleep 900
          # Additional monitoring...

      - name: Full rollout
        if: success()
        run: |
          kubectl set image deployment/app-stable app=$IMAGE
          kubectl delete trafficsplit app-canary

      - name: Rollback on failure
        if: failure()
        run: |
          kubectl rollout undo deployment/app --namespace=canary
          kubectl delete trafficsplit app-canary || true
```

### GitLab CI Canary

```yaml
# .gitlab-ci.yml - Canary
stages:
  - build
  - canary
  - promote
  - rollback

canary:5:
  stage: canary
  script:
    - kubectl set image deployment/app-canary app=$IMAGE
    - kubectl rollout status deployment/app-canary
    - |
      kubectl patch service app -p '
        {"spec":{"selector":null}}
      '
    - |
      kubectl apply -f - <<EOF
      apiVersion: split.smi-spec.io/v1alpha1
      kind: TrafficSplit
      metadata:
        name: app-canary
      spec:
        service: app
        backends:
        - service: app-stable
          weight: 95
        - service: app-canary
          weight: 5
      EOF
  environment:
    name: canary
    on_stop: rollback:canary

monitor:canary:
  stage: canary
  needs: [canary:5]
  script:
    - sleep 600
    - |
      ERROR_RATE=$(curl -s "$PROMETHEUS_URL/api/v1/query?query=rate(http_requests_total{status=~'5..'}[5m])" | jq -r '.data.result[0].value[1]')
      if (( $(echo "$ERROR_RATE > 0.01" | bc -l) )); then
        echo "Error rate too high"
        exit 1
      fi

promote:25:
  stage: promote
  needs: [monitor:canary]
  script:
    - |
      kubectl apply -f - <<EOF
      apiVersion: split.smi-spec.io/v1alpha1
      kind: TrafficSplit
      metadata:
        name: app-canary
      spec:
        service: app
        backends:
        - service: app-stable
          weight: 75
        - service: app-canary
          weight: 25
      EOF
  when: manual

promote:full:
  stage: promote
  needs: [promote:25]
  script:
    - kubectl set image deployment/app-stable app=$IMAGE
    - kubectl delete trafficsplit app-canary
  when: manual

rollback:canary:
  stage: rollback
  script:
    - kubectl rollout undo deployment/app-canary
    - kubectl delete trafficsplit app-canary || true
  when: manual
  environment:
    name: canary
    action: stop
```

## Rolling Deployment

### Kubernetes Rolling Update

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
spec:
  replicas: 4
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: app
        image: myapp:latest
        ports:
        - containerPort: 8080
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /health/live
            port: 8080
          initialDelaySeconds: 15
          periodSeconds: 20
```

### Docker Swarm Rolling

```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  app:
    image: myapp:${VERSION}
    deploy:
      replicas: 4
      update_config:
        parallelism: 1
        delay: 10s
        failure_action: rollback
        monitor: 30s
        max_failure_ratio: 0.1
      rollback_config:
        parallelism: 1
        delay: 10s
      restart_policy:
        condition: on-failure
        max_attempts: 3
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

## Health Check Endpoints

```php
<?php
// src/Api/Action/HealthAction.php

declare(strict_types=1);

namespace App\Api\Action;

use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;

final readonly class HealthAction
{
    public function __construct(
        private DatabaseHealthChecker $database,
        private CacheHealthChecker $cache,
        private QueueHealthChecker $queue,
    ) {}

    public function ready(ServerRequestInterface $request): ResponseInterface
    {
        $checks = [
            'database' => $this->database->check(),
            'cache' => $this->cache->check(),
            'queue' => $this->queue->check(),
        ];

        $healthy = !in_array(false, $checks, true);

        return new JsonResponse(
            [
                'status' => $healthy ? 'healthy' : 'unhealthy',
                'checks' => $checks,
                'timestamp' => (new DateTimeImmutable())->format('c'),
            ],
            $healthy ? 200 : 503
        );
    }

    public function live(ServerRequestInterface $request): ResponseInterface
    {
        return new JsonResponse([
            'status' => 'alive',
            'timestamp' => (new DateTimeImmutable())->format('c'),
        ]);
    }
}
```

## Generation Instructions

1. **Identify deployment target:**
   - Kubernetes / Docker Swarm / VMs
   - Cloud provider (AWS, GCP, Azure)
   - CI platform (GitHub, GitLab)

2. **Select strategy:**
   - Blue-Green: Instant switch, 2x resources
   - Canary: Gradual rollout, metrics-based
   - Rolling: Gradual replace, minimal resources

3. **Configure health checks:**
   - Readiness probe (can accept traffic)
   - Liveness probe (is alive)
   - Startup probe (is ready to be probed)

4. **Set up monitoring:**
   - Error rate thresholds
   - Latency thresholds
   - Custom metrics

5. **Define rollback triggers:**
   - Automatic on health check failure
   - Manual option always available

## Usage

Provide:
- Deployment target (K8s, Swarm, VMs)
- Strategy (blue-green, canary, rolling)
- CI platform (GitHub, GitLab)
- Health check endpoints
- Rollback criteria

The generator will:
1. Create deployment workflow
2. Configure health checks
3. Set up traffic management
4. Add monitoring hooks
5. Implement rollback procedures
