# Production Deploy

Bridge 서버와 연동하여 단계별 배포 상태를 추적하고, Docker 컨테이너 기반으로 격리된 실행 환경을 제공합니다.

## 🎯 주요 특징

- **단계별 상태 추적**: Route53 → ALB → K8S → Ingress → Domain Mapping
- **콜백 시스템**: 각 단계별 실시간 상태 Bridge 서버로 전송
- **컨테이너 기반**: Docker로 격리된 실행 환경
- **API 연동**: REST API를 통한 배포 관리

## 📁 디렉토리 구조

```
production-deploy/
├── playbooks/
│   └── deploy-production.yml     # 메인 배포 플레이북
├── roles/                        # 단계별 배포 roles
│   ├── aws-route53/             # Route53 DNS 관리
│   ├── aws-loadbalancer/        # AWS ALB 관리
│   ├── k8s-deployment/          # Kubernetes 애플리케이션 배포
│   ├── k8s-service/             # Kubernetes 서비스 생성
│   └── k8s-ingress/             # Kubernetes Ingress 설정
├── plugins/callback/
│   └── bridge_callback.py       # Bridge 서버 콜백 플러그인
├── scripts/
│   ├── setup-production.sh      # 전체 환경 설정
│   └── test-deployment.sh       # 배포 테스트 도구
├── inventory/hosts.yml           # 인벤토리 및 변수 설정
├── ansible.cfg                  # Ansible 설정
├── requirements.yml             # 컬렉션 의존성
├── Dockerfile                   # Ansible Runner 컨테이너
└── docker-compose.yml           # 개발용 구성
```

## 🚀 빠른 시작

### 1. 환경 설정
```bash
# 전체 환경 자동 설정 (Bridge 서버 Docker + Runner 이미지)
./scripts/setup-production.sh

# 또는 단계별 설정
./scripts/setup-production.sh bridge    # Bridge 서버 Docker만
./scripts/setup-production.sh runner    # Runner 이미지만
./scripts/setup-production.sh verify    # 환경 검증만
```

> **🐳 Docker 기반**: Bridge 서버는 Docker 컨테이너로 실행되므로 Go 설치가 필요하지 않습니다.

### 2. 배포 테스트
```bash
# 데모 배포 실행
./scripts/setup-production.sh demo

# 또는 수동 테스트
./scripts/test-deployment.sh full
```

### 3. 배포 상태 확인
```bash
# 전체 배포 목록
curl -s http://localhost:8080/api/v1/deployments | jq

# 특정 배포 상태
curl -s http://localhost:8080/api/v1/deployments/1 | jq

# 배포 단계별 상태
curl -s http://localhost:8080/api/v1/deployments/1/steps | jq
```

## 🔄 배포 워크플로우

### 1. Bridge 서버를 통한 자동 배포
```bash
# 1. 배포 요청 (Frontend → Bridge 서버)
curl -X POST http://localhost:8080/api/v1/deployments \
  -H "Content-Type: application/json" \
  -d '{
    "name": "my-app",
    "docker_image": "nginx:alpine", 
    "domain": "example.com",
    "env_config": "ENVIRONMENT=production"
  }'

# 2. Bridge 서버가 자동으로 Runner 컨테이너 실행
# 3. Runner가 단계별로 콜백 API 호출
# 4. 실시간 상태 확인 가능
```

### 2. 직접 실행 (개발/디버깅용)
```bash
# 환경변수 설정
export DEPLOYMENT_ID=1
export DOCKER_IMAGE=nginx:alpine
export DOMAIN=example.com
export BRIDGE_SERVER_URL=http://localhost:8080

# Ansible 플레이북 직접 실행
ansible-playbook playbooks/deploy-production.yml -v
```

## 📋 배포 단계 상세

| 단계 | 설명 | 주요 작업 |
|------|------|----------|
| **1. Route53** | DNS 설정 | 호스팅 영역 생성, A 레코드 등록 |
| **2. Load Balancer** | ALB 설정 | 보안그룹, ALB, 대상그룹 생성 |
| **3. K8S Deployment** | 앱 배포 | 네임스페이스, ConfigMap, Deployment |
| **4. K8S Service** | 서비스 생성 | ClusterIP, LoadBalancer 서비스 |
| **5. Ingress** | 도메인 연결 | Ingress Controller, Ingress 리소스 |

## 🔧 환경 변수

### 필수 변수
| 변수명 | 설명 | 예시 |
|--------|------|------|
| `DEPLOYMENT_ID` | 배포 고유 ID | 1 |
| `DOCKER_IMAGE` | 배포할 도커 이미지 | nginx:alpine |
| `DOMAIN` | 배포 도메인 | example.com |
| `BRIDGE_SERVER_URL` | Bridge 서버 URL | http://localhost:8080 |

### 선택 변수
| 변수명 | 설명 | 기본값 |
|--------|------|--------|
| `APP_NAME` | 애플리케이션명 | sample-app |
| `ENV_CONFIG` | 환경설정 | (빈 문자열) |
| `AWS_ACCESS_KEY_ID` | AWS 액세스 키 | test |
| `AWS_SECRET_ACCESS_KEY` | AWS 시크릿 키 | test |

## 🔌 콜백 플러그인

`plugins/callback/bridge_callback.py`는 배포 진행 상황을 실시간으로 Bridge 서버에 전송합니다.

### 콜백 동작
- **태스크 시작**: `running` 상태 전송
- **태스크 완료**: `completed` 상태 전송
- **태스크 실패**: `failed` 상태 전송

### 태스크 매핑
```python
step_mapping = {
    'route53': ['route53', 'dns'],
    'load_balancer': ['lb', 'load_balancer', 'alb'],
    'k8s_service': ['service', 'k8s_service', 'kubernetes'],
    'ingress': ['ingress', 'k8s_ingress'],
    'domain_mapping': ['domain', 'mapping']
}
```

## 🐳 Docker 사용

### Bridge 서버 (자동 실행)
```bash
# setup-production.sh에서 자동으로 실행됨
# 수동으로 빌드/실행하려면:
cd bridge-server
docker build -t bridge-server:latest .
docker run -d \
  --name bridge-server \
  -p 8080:8080 \
  -v $(pwd):/app/data \
  -v /var/run/docker.sock:/var/run/docker.sock \
  bridge-server:latest
```

### Ansible Runner 이미지
```bash
# 이미지 빌드
docker build -t ansible-runner:latest .

# 수동 실행 (일반적으로 Bridge 서버에서 자동 실행)
docker run --rm \
  -e DEPLOYMENT_ID=1 \
  -e DOCKER_IMAGE=nginx:alpine \
  -e DOMAIN=example.com \
  -e BRIDGE_SERVER_URL=http://host.docker.internal:8080 \
  -v $(pwd):/ansible \
  -v ~/.kube:/root/.kube:ro \
  --network host \
  ansible-runner:latest \
  ansible-playbook playbooks/deploy-production.yml -v
```

### Docker Compose 개발용
```bash
# 환경변수 설정 후
docker-compose up
```

### 컨테이너 관리
```bash
# Bridge 서버 상태 확인
docker ps --filter "name=bridge-server"

# Bridge 서버 로그 확인  
docker logs bridge-server

# Bridge 서버 재시작
docker restart bridge-server
```

## 🎯 태그별 실행

```bash
# 특정 단계만 실행
ansible-playbook playbooks/deploy-production.yml --tags route53
ansible-playbook playbooks/deploy-production.yml --tags load_balancer
ansible-playbook playbooks/deploy-production.yml --tags k8s_service
ansible-playbook playbooks/deploy-production.yml --tags ingress
ansible-playbook playbooks/deploy-production.yml --tags domain_mapping

# 여러 단계 실행
ansible-playbook playbooks/deploy-production.yml --tags "route53,load_balancer"
```

## 🧪 테스트 도구

### 전체 테스트
```bash
./scripts/test-deployment.sh full
```

### 개별 테스트
```bash
./scripts/test-deployment.sh health     # Bridge 서버 상태
./scripts/test-deployment.sh create     # 새 배포 생성
./scripts/test-deployment.sh list       # 배포 목록
./scripts/test-deployment.sh monitor 1  # 배포 모니터링
./scripts/test-deployment.sh callback 1 # 콜백 테스트
```

## 🧹 정리 도구

### 환경 정리
```bash
# 전체 정리 (Bridge 서버, 컨테이너, K8s, DB)
./scripts/cleanup-production.sh --all

# 또는 setup-production.sh를 통해
./scripts/setup-production.sh cleanup
```

### 선택적 정리
```bash
./scripts/cleanup-production.sh --bridge      # Bridge 서버만
./scripts/cleanup-production.sh --containers  # Ansible Runner 컨테이너만
./scripts/cleanup-production.sh --kubernetes  # Kubernetes 리소스만
./scripts/cleanup-production.sh --database    # 데이터베이스만
```

### 기본 정리 (컨테이너 + K8s)
```bash
./scripts/cleanup-production.sh
```

## 🐛 문제 해결

### 일반적인 문제

1. **Bridge 서버 연결 실패**
   ```bash
   curl http://localhost:8080/api/v1/health
   ```

2. **Docker 이미지 문제**
   ```bash
   docker build -t ansible-runner:latest .
   docker images | grep ansible-runner
   ```

3. **Kubernetes 접근 문제**
   ```bash
   kubectl cluster-info
   kubectl get nodes
   ```

4. **콜백 전송 실패**
   ```bash
   # 로그 확인
   docker logs ansible-runner-<deployment_id>
   ```

### 디버깅 모드

```bash
# 상세 로그
ansible-playbook playbooks/deploy-production.yml -vvv

# 드라이런
ansible-playbook playbooks/deploy-production.yml --check

# 특정 태스크부터 실행
ansible-playbook playbooks/deploy-production.yml --start-at-task="Route53 설정"
```

## 🔗 관련 문서

- **[메인 프로젝트](../README.md)** - 전체 프로젝트 개요
- **[Bridge 서버](../bridge-server/README.md)** - API 서버 문서
- **[Production 가이드](../README-PRODUCTION.md)** - 전체 시스템 가이드
- **[Simple Test](../simple-test/README.md)** - 기본 학습용

## ⚠️ 주의사항

- 이 시스템은 **개발/테스트 환경**용입니다
- 실제 프로덕션에서는 보안 설정을 강화하세요
- AWS 인증 정보는 실제 값으로 변경하세요
- Kubernetes 클러스터 리소스 제한을 적절히 설정하세요