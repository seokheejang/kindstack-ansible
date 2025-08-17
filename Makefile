# Ansible 프로젝트용 Makefile
# 자주 사용하는 명령어들을 간단하게 실행할 수 있도록 구성

.PHONY: help setup deploy clean check dry-run inventory ping galaxy install advanced

# 기본 타겟
.DEFAULT_GOAL := help

# 변수 정의
PLAYBOOK := playbooks/deploy-nextjs.yml
INVENTORY := inventory/hosts.yml

# 도움말
help: ## 사용 가능한 명령어 목록을 표시합니다
	@echo "🚀 Ansible KindStack 프로젝트"
	@echo ""
	@echo "사용 가능한 명령어:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "고급 명령어는 'make advanced'를 실행하세요"

# 환경 설정
setup: ## 환경 설정 및 의존성 설치
	@echo "🔧 환경을 설정합니다..."
	@./scripts/setup.sh

# 기본 배포
deploy: ## Next.js 앱을 배포합니다
	@echo "🚀 Next.js 앱을 배포합니다..."
	@ansible-playbook $(PLAYBOOK)

# Full Stack 배포
deploy-full: ## AWS + Kubernetes 전체 스택을 배포합니다
	@echo "🏗️  Full Stack을 배포합니다..."
	@ansible-playbook playbooks/deploy-full-stack.yml

# 빠른 배포 (스크립트 사용)
deploy-quick: ## 배포 스크립트를 사용한 빠른 배포
	@./scripts/deploy.sh

# 문법 검사
check: ## 플레이북 문법을 검사합니다
	@echo "✅ 플레이북 문법을 검사합니다..."
	@ansible-playbook $(PLAYBOOK) --syntax-check

# 드라이런
dry-run: ## 실제 변경 없이 시뮬레이션 실행
	@echo "🧪 드라이런 모드로 실행합니다..."
	@ansible-playbook $(PLAYBOOK) --check --diff

# 인벤토리 확인
inventory: ## 인벤토리 정보를 확인합니다
	@echo "📋 인벤토리 정보:"
	@ansible-inventory --list --yaml

# 연결 테스트
ping: ## 호스트 연결을 테스트합니다
	@echo "🏓 호스트 연결을 테스트합니다..."
	@ansible all -m ansible.builtin.ping

# Galaxy 컬렉션 설치
galaxy: ## Ansible Galaxy 컬렉션을 설치합니다
	@echo "📦 Galaxy 컬렉션을 설치합니다..."
	@ansible-galaxy collection install -r requirements.yml --force

# 태그별 배포
deploy-namespace: ## 네임스페이스만 생성
	@ansible-playbook $(PLAYBOOK) --tags namespace

deploy-config: ## ConfigMap만 생성
	@ansible-playbook $(PLAYBOOK) --tags configmap

deploy-app: ## 애플리케이션만 배포
	@ansible-playbook $(PLAYBOOK) --tags deployment

deploy-service: ## 서비스만 생성
	@ansible-playbook $(PLAYBOOK) --tags service

deploy-verify: ## 배포 상태만 확인
	@ansible-playbook $(PLAYBOOK) --tags verify

# Full Stack 태그별 배포
deploy-aws: ## AWS 인프라만 배포
	@ansible-playbook playbooks/deploy-full-stack.yml --tags aws

deploy-enhanced: ## 향상된 K8s 리소스만 배포 (Ingress, LoadBalancer)
	@ansible-playbook playbooks/deploy-full-stack.yml --tags enhanced

# 클린업
clean: ## 배포된 리소스와 임시 파일을 정리합니다 (K8s + LocalStack)
	@echo "🧹 리소스를 정리합니다..."
	@./scripts/cleanup.sh

clean-all: ## 모든 것을 완전히 정리합니다 (Kind 클러스터 포함)
	@echo "🧹 모든 것을 완전히 정리합니다..."
	@./scripts/cleanup.sh --all

clean-k8s: ## Kubernetes 리소스만 정리합니다
	@echo "🧹 Kubernetes 리소스를 정리합니다..."
	@./scripts/cleanup.sh --kubernetes

clean-localstack: ## LocalStack만 재시작합니다
	@echo "🧹 LocalStack을 재시작합니다..."
	@./scripts/cleanup.sh --localstack

clean-temp: ## Ansible 임시 파일만 정리
	@echo "🗑️  임시 파일을 정리합니다..."
	@./scripts/ansible-commands.sh clean

# 로그 및 디버깅
logs: ## 배포된 앱의 로그를 확인합니다
	@echo "📊 애플리케이션 로그:"
	@kubectl logs -f deployment/nextjs-sample-deployment -n nextjs-sample

status: ## 배포 상태를 확인합니다
	@echo "📈 배포 상태:"
	@kubectl get all -n nextjs-sample

# 개발용 명령어들
dev-check: galaxy check ## 개발용: 컬렉션 설치 + 문법 검사
	@echo "✅ 개발 환경 검사 완료"

dev-deploy: dev-check dry-run deploy ## 개발용: 전체 검증 후 배포
	@echo "🎉 개발 배포 완료"

# 고급 명령어 도움말
advanced: ## 고급 Ansible 명령어들을 표시합니다
	@./scripts/ansible-commands.sh advanced

# 빌드 타겟들
install: setup galaxy ## 전체 설치 (환경설정 + Galaxy)

test: check dry-run ## 테스트 (문법검사 + 드라이런)

all: install test deploy ## 전체 프로세스 실행

# Vault 관련
vault-create: ## 새 Vault 파일을 생성합니다
	@./scripts/ansible-commands.sh vault-create

vault-edit: ## Vault 파일을 편집합니다  
	@./scripts/ansible-commands.sh vault-edit

# 정보 확인
info: ## 환경 정보를 표시합니다
	@echo "📊 환경 정보:"
	@echo "  - Ansible: $$(ansible --version | head -n1)"
	@echo "  - kubectl: $$(kubectl version --client --short 2>/dev/null || echo 'N/A')"
	@echo "  - Kind: $$(kind version 2>/dev/null || echo 'N/A')"
	@echo "  - 현재 컨텍스트: $$(kubectl config current-context 2>/dev/null || echo 'N/A')"
	@echo "  - LocalStack: $$(curl -s http://localhost:4566/health >/dev/null && echo '✅ 실행중' || echo '❌ 정지됨')"
