# KindStack Ansible

로컬 환경에서 **Kind** 클러스터와 **LocalStack**을 사용한 Ansible 테스트 프로젝트입니다.

## 🎯 목적

- Kind 클러스터에 Next.js SSR 앱 배포 자동화
- LocalStack을 통한 AWS 서비스 시뮬레이션
- Ansible을 활용한 인프라 코드 관리

## 📁 프로젝트 구조

```
kindstack-ansible/
├── ansible.cfg                    # Ansible 설정
├── requirements.yml               # Ansible 컬렉션 의존성
├── docker-compose.yaml           # LocalStack 설정
├── inventory/
│   └── hosts.yml                 # 인벤토리 설정
├── roles/
│   └── nextjs-deploy/           # Next.js 배포 역할
│       ├── tasks/main.yml       # 배포 태스크
│       └── meta/main.yml        # 메타데이터
├── playbooks/
│   └── deploy-nextjs.yml        # Next.js 배포 플레이북
└── scripts/
    ├── setup.sh                 # 환경 설정 스크립트
    ├── deploy.sh                # 배포 스크립트
    └── cleanup.sh               # 정리 스크립트
```

## 🚀 빠른 시작

### 1. 환경 설정

```bash
# 환경 설정 및 의존성 설치
./scripts/setup.sh
```

이 스크립트는 다음을 수행합니다:
- 필수 도구 설치 확인 (ansible, kubectl, kind, docker)
- Ansible 컬렉션 설치
- Kind 클러스터 생성 (없는 경우)
- LocalStack 시작

### 2. Next.js 앱 배포

```bash
# 간단한 배포
./scripts/deploy.sh

# 또는 직접 플레이북 실행
ansible-playbook playbooks/deploy-nextjs.yml
```

### 3. 앱 접속

```bash
# 브라우저에서 접속
open http://localhost:30080
```

### 4. 정리

```bash
# 테스트 환경 정리
./scripts/cleanup.sh
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

# 배포
make deploy

# 문법 검사
make check

# 드라이런
make dry-run

# 상태 확인
make status

# 로그 확인
make logs

# 정리
make clean
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

1. **Kind 클러스터 접근 불가**
   ```bash
   kind create cluster --name kind
   kubectl cluster-info --context kind-kind
   ```

2. **LocalStack 연결 오류**
   ```bash
   docker-compose up -d
   curl http://localhost:4566/health
   ```

3. **권한 문제**
   ```bash
   chmod +x scripts/*.sh
   ```

4. **Ansible 컬렉션 문제**
   ```bash
   ansible-galaxy collection install -r requirements.yml --force
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

## 📄 라이선스

MIT License - 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## 🙋‍♂️ 지원

문제가 있거나 질문이 있으시면 이슈를 생성해 주세요!
