# KindStack Ansible Project

**로컬 환경에서 Ansible을 통한 완전한 배포 자동화 프로젝트**

이 프로젝트는 Kind 클러스터와 LocalStack을 활용하여 개발부터 실무급 배포까지 다양한 시나리오를 제공합니다.

## 📁 프로젝트 구조

```
kindstack-ansible/
├── simple-test/              # 🎓 기본 학습용 (Ansible 기초)
├── production-deploy/        # 🚀 실무급 배포 시스템  
├── bridge-server/           # 🌉 Golang Bridge 서버
└── docs/                    # 📚 상세 문서들
```

## 🎯 사용 목적별 가이드

### 🎓 Ansible 학습 & 기초 테스트
**→ [`simple-test/`](simple-test/) 디렉토리 사용**

```bash
cd simple-test
./scripts/setup.sh
ansible-playbook playbooks/deploy-nextjs.yml
```

- 기본 Kubernetes 배포 학습
- LocalStack AWS 시뮬레이션  
- Ansible 플레이북 기초

👉 **[Simple Test 상세 가이드](simple-test/README.md)**

### 🚀 실무급 배포 시스템
**→ [`production-deploy/`](production-deploy/) + [`bridge-server/`](bridge-server/) 사용**

```bash
production-deploy/scripts/setup-production.sh
```

- Bridge 서버를 통한 배포 요청 관리
- Ansible Runner 컨테이너 자동 실행  
- 단계별 배포 상태 추적 (Route53 → ALB → K8S → Ingress)
- REST API 기반 배포 관리

👉 **[Production 상세 가이드](README-PRODUCTION.md)**

## 🔄 워크플로우 비교

| 구분 | Simple Test | Production System |
|------|-------------|-------------------|
| **대상** | 학습자, 기초 테스트 | 실무 개발자, 자동화 |
| **실행** | 직접 ansible-playbook | REST API + Bridge 서버 |
| **상태관리** | 수동 확인 | 자동 추적 & DB 저장 |
| **확장성** | 제한적 | 높음 (API 기반) |

## 🚀 빠른 시작

### Option 1: 기본 학습 (추천)
```bash
cd simple-test
./scripts/setup.sh
ansible-playbook playbooks/deploy-nextjs.yml
curl http://localhost
```

### Option 2: 실무급 시스템
```bash
production-deploy/scripts/setup-production.sh
curl -X POST http://localhost:8080/api/v1/deployments \
  -H "Content-Type: application/json" \
  -d '{"name":"my-app","docker_image":"nginx:alpine","domain":"example.com"}'
```

## 🛠️ 요구사항

### 공통
- Docker & Docker Compose
- kubectl  
- kind (Kubernetes in Docker)

### Production 추가 요구사항
- Go >= 1.21 (Bridge 서버용)
- jq (선택사항)

## 📚 상세 문서

| 문서 | 설명 |
|------|------|
| **[Simple Test 가이드](simple-test/README.md)** | 기본 학습용 상세 설명 |
| **[Production 가이드](README-PRODUCTION.md)** | 실무급 시스템 전체 가이드 |
| **[Bridge 서버](bridge-server/README.md)** | Golang 웹 서버 API 문서 |
| **[Production Deploy](production-deploy/README.md)** | Ansible Runner 상세 설명 |

## 🐛 문제 해결

### Simple Test
```bash
cd simple-test && ./scripts/cleanup.sh && ./scripts/setup.sh
```

### Production System  
```bash
# 정리 후 재설정
production-deploy/scripts/cleanup-production.sh --all
production-deploy/scripts/setup-production.sh

# 또는 간단히
production-deploy/scripts/setup-production.sh cleanup
production-deploy/scripts/setup-production.sh
```

## 🚀 다음 단계

1. **처음 사용자** → `simple-test/`에서 Ansible 기초 학습
2. **개발자** → `production-deploy/`로 실무 워크플로우 이해  
3. **실무 적용** → Bridge 서버 API를 Frontend와 연동

---

**💡 시작 가이드**: 처음이라면 [`simple-test/README.md`](simple-test/README.md)부터 읽어보세요!