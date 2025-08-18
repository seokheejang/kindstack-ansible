# Simple Test - Ansible 기초 학습

로컬 환경에서 **Kind** 클러스터와 **LocalStack**을 사용한 **Ansible 기초 학습** 프로젝트입니다.

> 🎓 **학습 목적**: Ansible 플레이북 기초와 Kubernetes 배포 이해  
> 🚀 **실무용**: 고급 기능은 [`../production-deploy/`](../production-deploy/)를 사용하세요

## 🎯 학습 목표

- **Ansible 플레이북** 작성 및 실행 방법 익히기
- **Kubernetes 리소스** 배포 자동화 이해
- **LocalStack**으로 AWS 서비스 시뮬레이션 경험
- **Kind 클러스터** + **Ingress** 환경 구축
- **도메인 기반 접속** 설정 방법 학습

## 📁 프로젝트 구조

```
simple-test/
├── ansible.cfg                    # Ansible 설정
├── requirements.yml               # Ansible 컬렉션 의존성
├── docker-compose.yaml           # LocalStack 설정
├── kind-config.yaml              # Kind 클러스터 설정 (Ingress 지원)
├── inventory/
│   └── hosts.yml                 # 인벤토리 및 변수 설정
├── roles/
│   ├── nextjs-deploy/           # 기본 애플리케이션 배포
│   ├── aws-infrastructure/      # AWS 인프라 관리 (LocalStack)
│   └── k8s-enhanced/           # 향상된 K8s 리소스 (Ingress, LoadBalancer)
├── playbooks/
│   ├── deploy-nextjs.yml        # 기본 Next.js 배포 플레이북
│   └── deploy-full-stack.yml    # 통합 Full Stack 배포 플레이북
└── scripts/
    ├── setup.sh                 # 환경 설정
    ├── deploy.sh                # 기본 배포 스크립트
    ├── cleanup.sh               # 정리 스크립트
    └── ansible-commands.sh      # Ansible 유틸리티 명령어
```

## 🚀 빠른 시작

### 1. 환경 설정

```bash
cd simple-test

# 완전 자동 환경 설정 (권장)
./scripts/setup.sh
```

### 2. 기본 배포

```bash
# 기본 Next.js 애플리케이션 배포
ansible-playbook playbooks/deploy-nextjs.yml

# 또는 Full Stack 배포
ansible-playbook playbooks/deploy-full-stack.yml
```

### 3. 앱 접속

```bash
# 직접 접속
curl http://localhost

# 커스텀 도메인 접속 (hosts 파일 설정 후)
curl -H "Host: nextjs-sample.example.local" http://localhost
```

### 4. 정리

```bash
# 리소스 정리
./scripts/cleanup.sh
```

## 🔧 주요 기능

### 기본 배포 (deploy-nextjs.yml)
- Kubernetes 네임스페이스 생성
- ConfigMap 설정
- Deployment 배포
- Service 생성
- 기본 접속 확인

### Full Stack 배포 (deploy-full-stack.yml)
- ✅ **AWS Route53** 호스팅 영역 (LocalStack)
- ✅ **Application Load Balancer** 시뮬레이션
- ✅ **Kubernetes 애플리케이션** 배포
- ✅ **NGINX Ingress Controller** 설치
- ✅ **LoadBalancer Service** 생성
- ✅ **Ingress 리소스** 생성

## 📊 유용한 명령어들

### Ansible 실행
```bash
# 문법 검사
ansible-playbook playbooks/deploy-nextjs.yml --syntax-check

# 드라이런 모드
ansible-playbook playbooks/deploy-nextjs.yml --check

# 상세 로그로 실행
ansible-playbook playbooks/deploy-nextjs.yml -vvv

# 특정 태그만 실행
ansible-playbook playbooks/deploy-full-stack.yml --tags enhanced
```

### Kubernetes 확인
```bash
# 모든 리소스 확인
kubectl get all -n nextjs-sample

# Pod 로그 확인
kubectl logs -f deployment/nextjs-sample-deployment -n nextjs-sample

# 서비스 확인
kubectl get svc -n nextjs-sample
```

### LocalStack 확인
```bash
# LocalStack 상태 확인
curl http://localhost:4566/health

# Route53 도메인 확인
aws --endpoint-url=http://localhost:4566 route53 list-hosted-zones
```

## 🐛 문제 해결

### 일반적인 문제들

1. **Kind 클러스터 접근 불가**
   ```bash
   # 클러스터 재생성
   ./scripts/cleanup.sh && ./scripts/setup.sh
   ```

2. **LocalStack 연결 오류**
   ```bash
   # LocalStack 재시작
   docker-compose down && docker-compose up -d
   ```

3. **Ingress 접속 불가**
   ```bash
   # Ingress Controller 상태 확인
   kubectl get pods -n ingress-nginx
   
   # 포트 매핑 확인
   docker ps --filter "name=kind-control-plane"
   ```

## 🎓 학습 진행 순서

1. **기초 이해**: 이 디렉토리에서 Ansible 기본기 익히기
2. **실무 학습**: [`../production-deploy/`](../production-deploy/)에서 고급 워크플로우 이해
3. **시스템 연동**: [`../bridge-server/`](../bridge-server/)에서 API 기반 배포 관리 학습

### 다음 단계로 이동
```bash
# Production 환경 체험
cd ../production-deploy
./scripts/setup-production.sh demo
```

## ⚠️ 주의사항

- 이 코드는 **학습 및 로컬 테스트 전용**입니다
- 모든 인증 정보는 `test` 값을 사용합니다
- 실제 프로덕션에서는 사용하지 마세요
- 더 진보된 기능은 `production-deploy` 디렉토리를 사용하세요

## 🔗 관련 문서

- [Production 환경 문서](../README-PRODUCTION.md)
- [Bridge 서버 문서](../bridge-server/README.md)
- [Production Deploy 문서](../production-deploy/README.md)
