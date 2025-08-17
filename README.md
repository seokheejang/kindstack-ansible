# KindStack Ansible

로컬 환경에서 **Kind** 클러스터와 **LocalStack**을 사용한 **Full Stack** Ansible 배포 프로젝트입니다.

## 🎯 목적

- **완전한 로컬 AWS + Kubernetes 환경** 구축 및 자동화
- **AWS Route53 + LoadBalancer + Kubernetes Ingress** 통합 배포  
- **포트 포워딩 없이 도메인으로 직접 접속** 가능한 환경
- LocalStack을 통한 AWS 서비스 시뮬레이션
- Ansible을 활용한 Infrastructure as Code 관리

## 📁 프로젝트 구조

```
kindstack-ansible/
├── ansible.cfg                    # Ansible 설정
├── requirements.yml               # Ansible 컬렉션 의존성 (kubernetes.core, amazon.aws)
├── docker-compose.yaml           # LocalStack 설정 (Route53, ELB, EC2 포함)
├── kind-config.yaml              # Kind 클러스터 설정 (Ingress 지원)
├── inventory/
│   └── hosts.yml                 # 인벤토리 및 변수 설정
├── roles/
│   ├── nextjs-deploy/           # 기본 애플리케이션 배포
│   │   ├── tasks/main.yml       # 배포 태스크
│   │   ├── templates/           # Kubernetes 매니페스트 템플릿
│   │   │   ├── deployment.yaml.j2
│   │   │   └── service.yaml.j2
│   │   └── meta/main.yml        # 메타데이터
│   ├── aws-infrastructure/      # AWS 인프라 관리 (LocalStack)
│   │   ├── tasks/main.yml       # Route53, ALB 시뮬레이션
│   │   └── meta/main.yml
│   └── k8s-enhanced/           # 향상된 K8s 리소스 (Ingress, LoadBalancer)
│       ├── tasks/main.yml       # Ingress Controller, LoadBalancer 배포
│       └── meta/main.yml
├── playbooks/
│   ├── deploy-nextjs.yml        # 기본 Next.js 배포 플레이북
│   └── deploy-full-stack.yml    # 통합 Full Stack 배포 플레이북
└── scripts/
    ├── setup.sh                 # 환경 설정 (Kind 설정 포함)
    ├── deploy.sh                # 기본 배포 스크립트
    ├── cleanup.sh               # 강력한 정리 스크립트 (옵션별 정리)
    └── ansible-commands.sh      # Ansible 유틸리티 명령어
```

## 🚀 빠른 시작

### 1. 환경 설정

```bash
# 완전 자동 환경 설정 (권장)
./scripts/setup.sh
```

이 스크립트는 다음을 수행합니다:
- 필수 도구 설치 확인 (ansible, kubectl, kind, docker)
- Ansible 컬렉션 설치 (kubernetes.core, amazon.aws)
- **Ingress 지원 Kind 클러스터** 생성 (kind-config.yaml 사용)
- LocalStack 시작 (Route53, ELB, EC2 서비스 포함)

### 2. Full Stack 배포 🚀

```bash
# 완전한 스택 배포 (AWS + Kubernetes + Ingress)
make deploy-full

# 또는 직접 실행
ansible-playbook playbooks/deploy-full-stack.yml
```

이 명령어는 다음을 자동으로 배포합니다:
- ✅ **AWS Route53** 호스팅 영역 및 도메인 (LocalStack)
- ✅ **Application Load Balancer** 시뮬레이션
- ✅ **Kubernetes 애플리케이션** (Deployment, ConfigMap, Service)
- ✅ **NGINX Ingress Controller** 설치
- ✅ **LoadBalancer Service** 생성
- ✅ **Ingress 리소스** 생성 (도메인 연결)

### 3. 앱 접속 🌐

**포트 포워딩 없이 바로 접속 가능!**

```bash
# 1. 직접 접속 (가장 간단!)
curl http://localhost
# 브라우저: http://localhost

# 2. 커스텀 도메인 접속
echo "127.0.0.1 nextjs-sample.example.local" | sudo tee -a /etc/hosts
# 브라우저: http://nextjs-sample.example.local

# 3. Host 헤더 테스트
curl -H "Host: nextjs-sample.example.local" http://localhost
```

### 4. 정리 🧹

```bash
# 기본 정리 (K8s + LocalStack 재시작)
make clean

# 완전 정리 (Kind 클러스터까지 재생성)
make clean-all

# 선택적 정리
make clean-k8s        # Kubernetes만
make clean-localstack # LocalStack만
```

## 📋 필수 요구사항

### 🚀 자동 설치 (권장)

#### **Ubuntu 환경**
```bash
# 완전 자동 설치 (깨끗한 Ubuntu 시스템용)
./scripts/install-ubuntu.sh

# 최소 설치 (Ansible만)
./scripts/install-ubuntu.sh --minimal

# 시스템 확인만
./scripts/install-ubuntu.sh --check
```

#### **모든 OS (자동 감지)**
```bash
# OS를 자동 감지하여 설치
./scripts/setup.sh
```

### 🛠️ 수동 설치

#### **macOS**
```bash
# Homebrew 사용 (권장)
brew install ansible kubectl kind

# Docker Desktop은 별도 설치
# https://docs.docker.com/desktop/mac/install/
```

#### **Ubuntu**
```bash
# Ansible
sudo apt update
sudo apt install software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install ansible

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Docker
sudo apt install docker.io
sudo usermod -aG docker $USER
```

#### **CentOS/RHEL**
```bash
# Ansible
sudo yum install epel-release
sudo yum install ansible

# kubectl, Kind, Docker는 Ubuntu와 유사
```

## 🔧 설정 커스터마이징

### 앱 설정 변경

`inventory/hosts.yml` 파일에서 다음 설정을 변경할 수 있습니다:

```yaml
# Next.js 앱 설정
app_name: nextjs-sample           # 앱 이름
app_image: "vercel/next.js:canary" # Docker 이미지
app_port: 3000                    # 앱 포트
app_replicas: 1                   # 복제본 수
```

### LocalStack 설정 변경

`docker-compose.yaml` 파일에서 LocalStack 서비스를 조정할 수 있습니다:

```yaml
environment:
  - SERVICES=route53,s3,dynamodb  # 필요한 AWS 서비스 추가
  - AWS_DEFAULT_REGION=us-east-1
```

## 📊 유용한 명령어들

### 🚀 Makefile 사용 (권장)

```bash
# 도움말 확인
make help

# 환경 설정
make setup

# === 배포 명령어 ===
make deploy           # 기본 애플리케이션 배포
make deploy-full      # Full Stack 배포 (AWS + K8s + Ingress)
make deploy-aws       # AWS 인프라만 배포
make deploy-enhanced  # 향상된 K8s 리소스만 배포 (Ingress, LoadBalancer)

# === 정리 명령어 ===
make clean            # 기본 정리 (K8s + LocalStack 재시작)
make clean-all        # 완전 정리 (Kind 클러스터 포함)
make clean-k8s        # Kubernetes 리소스만 정리
make clean-localstack # LocalStack만 재시작

# === 유틸리티 ===
make check            # 문법 검사
make dry-run          # 드라이런
make status           # 상태 확인
make logs             # 로그 확인
```

### ⚙️ Ansible 전용 명령어

```bash
# Ansible 명령어 도구 사용
./scripts/ansible-commands.sh help

# 플레이북 문법 검사
./scripts/ansible-commands.sh check

# 드라이런 모드
./scripts/ansible-commands.sh dry-run

# 태그별 배포
./scripts/ansible-commands.sh deploy-tags

# 인벤토리 확인
./scripts/ansible-commands.sh inventory

# 연결 테스트
./scripts/ansible-commands.sh ping
```

### 🎯 태그별 배포

```bash
# 네임스페이스만 생성
make deploy-namespace

# ConfigMap만 생성  
make deploy-config

# 애플리케이션만 배포
make deploy-app

# 서비스만 생성
make deploy-service

# 배포 상태만 확인
make deploy-verify
```

### 🐛 디버깅 명령어

```bash
# 상세한 로그와 함께 실행
ansible-playbook playbooks/deploy-nextjs.yml -vvv

# 특정 호스트만 대상
ansible-playbook playbooks/deploy-nextjs.yml --limit localhost

# 특정 태스크부터 시작
ansible-playbook playbooks/deploy-nextjs.yml --start-at-task="배포 상태 확인"

# 프로파일링과 함께 실행
ansible-playbook playbooks/deploy-nextjs.yml --profile
```

### 🔍 Kubernetes 리소스 확인

```bash
# 모든 리소스 확인
kubectl get all -n nextjs-sample

# Pod 상태 확인
kubectl get pods -n nextjs-sample

# 서비스 확인
kubectl get svc -n nextjs-sample

# 로그 확인
kubectl logs -f deployment/nextjs-sample-deployment -n nextjs-sample
```

### ☁️ LocalStack 확인

```bash
# LocalStack 상태 확인
curl http://localhost:4566/health

# AWS CLI로 LocalStack 사용
aws --endpoint-url=http://localhost:4566 s3 ls
```

## 🐛 문제 해결

### 일반적인 문제들

1. **Ingress 접속이 안 될 때** 🌐
   ```bash
   # Kind 클러스터 포트 매핑 확인
   docker ps --filter "name=kind-control-plane"
   
   # Ingress Controller 상태 확인
   kubectl get pods -n ingress-nginx
   kubectl get svc -n ingress-nginx
   
   # 클러스터 재생성 (포트 매핑 포함)
   make clean-all
   ```

2. **"ImagePullBackOff" 오류**
   ```bash
   # 이미지를 변경해서 재배포
   ansible-playbook playbooks/deploy-full-stack.yml --extra-vars "app_image=nginx:alpine"
   ```

3. **Webhook 연결 오류** (Ingress 생성 실패)
   ```bash
   # Ingress Controller가 완전히 준비될 때까지 대기
   kubectl wait --for=condition=ready pod -n ingress-nginx -l app.kubernetes.io/component=controller --timeout=300s
   
   # 또는 정리 후 재배포
   make clean && make deploy-full
   ```

4. **Kind 클러스터 접근 불가**
   ```bash
   # 클러스터 상태 확인
   kind get clusters
   kubectl cluster-info --context kind-kind
   
   # 클러스터 재생성
   make clean-all
   ```

5. **LocalStack 연결 오류**
   ```bash
   # LocalStack 상태 확인
   docker-compose ps
   curl http://localhost:4566/_localstack/health
   
   # LocalStack 재시작
   make clean-localstack
   ```

6. **권한 문제**
   ```bash
   chmod +x scripts/*.sh
   ```

7. **Ansible 컬렉션 문제**
   ```bash
   ansible-galaxy collection install -r requirements.yml --force
   ```

### 🔍 디버깅 팁

```bash
# 상세한 로그로 실행
ansible-playbook playbooks/deploy-full-stack.yml -vvv

# 특정 단계부터 실행
ansible-playbook playbooks/deploy-full-stack.yml --start-at-task="Ingress 리소스 생성"

# 태그별 실행
ansible-playbook playbooks/deploy-full-stack.yml --tags enhanced

# 현재 상태 확인
kubectl get all -A
make status
```

## 📝 개발 가이드

### 새로운 역할(Role) 추가

```bash
# 새 역할 생성
mkdir -p roles/new-role/{tasks,vars,defaults,meta}
touch roles/new-role/tasks/main.yml
touch roles/new-role/meta/main.yml
```

### 새로운 플레이북 추가

```bash
# 새 플레이북 생성
touch playbooks/new-playbook.yml
```

### 테스트

```bash
# 문법 검사
ansible-playbook playbooks/deploy-nextjs.yml --syntax-check

# 드라이런
ansible-playbook playbooks/deploy-nextjs.yml --check

# 특정 호스트만 대상
ansible-playbook playbooks/deploy-nextjs.yml --limit localhost
```

## ⚠️ 보안 주의사항

이 프로젝트는 **로컬 테스트 전용**입니다:

- 모든 인증 정보는 `test` 값을 사용합니다
- 실제 프로덕션에서는 절대 사용하지 마세요
- 민감한 정보는 Ansible Vault를 사용하세요

```bash
# 실제 환경에서는 이렇게 사용하세요
ansible-vault create secrets.yml
```

## 🆕 새로운 기능들 (최신 업데이트)

### ✨ **Webhook 대기 로직** 개선
- **Ingress 생성 실패 문제 해결**: NGINX Ingress Controller의 webhook이 완전히 준비될 때까지 자동 대기
- **안정적인 배포**: 더 이상 수동으로 Ingress를 생성할 필요 없음

### 🧹 **강력한 정리 시스템**
- **선택적 정리**: 필요한 구성 요소만 골라서 정리 가능
- **스마트 재시작**: LocalStack과 Kind 클러스터 자동 재생성
- **상태 확인**: 정리 후 전체 환경 상태를 자동으로 확인

### 🔧 **Kind 설정 파일**
- **`kind-config.yaml`**: Ingress 지원을 위한 포트 매핑 자동 설정
- **Host 포트 노출**: 80, 443 포트를 호스트에 직접 매핑

### 🎭 **Jinja2 템플릿**
- **타입 안전성**: Kubernetes 매니페스트의 정수/문자열 타입 문제 해결
- **동적 생성**: 환경에 따른 유연한 매니페스트 생성

## 🌐 도메인 접속 방법

### 1. 직접 접속 (가장 간단!) ⭐
```bash
curl http://localhost
# 또는 브라우저에서 http://localhost
```
**포트 포워딩 없이 바로 접속 가능합니다!**

### 2. 커스텀 도메인 접속 🏷️
`/etc/hosts` 파일에 다음 라인을 추가:
```bash
# 터미널에서 실행
echo "127.0.0.1 nextjs-sample.example.local" | sudo tee -a /etc/hosts
```

그 후 브라우저에서 접속:
```
http://nextjs-sample.example.local
```

### 3. Host 헤더를 사용한 접속 (테스트용) 🧪
```bash
curl -H "Host: nextjs-sample.example.local" http://localhost
curl -H "Host: localhost" http://localhost
```

## 🎯 주요 기능들

### 🚀 Full Stack 배포
**완전한 로컬 AWS + Kubernetes 환경**을 한 번에 구축:

```bash
make deploy-full
# 또는
ansible-playbook playbooks/deploy-full-stack.yml
```

**배포되는 구성 요소:**
- ☁️ **AWS Route53** (LocalStack) - 도메인 관리
- 🌐 **Application Load Balancer** (시뮬레이션)
- 🎭 **NGINX Ingress Controller** - HTTP/HTTPS 트래픽 관리
- ⚖️ **LoadBalancer Service** - AWS 연동
- 📦 **Kubernetes 애플리케이션** - 완전한 배포

### 🔧 개별 컴포넌트 배포
```bash
make deploy-aws      # AWS 인프라만 (Route53, ALB)
make deploy-enhanced # K8s 향상 기능만 (Ingress, LoadBalancer)
make deploy          # 기본 애플리케이션만
```

### 🧹 강력한 정리 시스템
```bash
make clean           # 기본 정리 (K8s + LocalStack 재시작)
make clean-all       # 완전 정리 (Kind 클러스터 재생성)
make clean-k8s       # Kubernetes 리소스만
make clean-localstack # LocalStack만
```

## 🚀 Git Repository 설정

```bash
# 저장소 초기화
git init
git add .
git commit -m "Initial commit: Ansible KindStack template"

# GitHub에 푸시
git remote add origin https://github.com/yourusername/kindstack-ansible.git
git branch -M main
git push -u origin main
```

## 🤝 기여 방법

1. 이 저장소를 포크합니다
2. 기능 브랜치를 생성합니다 (`git checkout -b feature/새기능`)
3. 변경사항을 커밋합니다 (`git commit -am '새 기능 추가'`)
4. 브랜치에 푸시합니다 (`git push origin feature/새기능`)
5. 풀 리퀘스트를 생성합니다
