#!/bin/bash

# Ansible 전용 명령어 스크립트
# 다양한 Ansible 작업을 위한 유틸리티 명령어들

set -e

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}==== $1 ====${NC}"
}

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_help() {
    echo "Ansible 명령어 도구"
    echo ""
    echo "사용법: $0 [명령어]"
    echo ""
    echo "사용 가능한 명령어:"
    echo "  check          - 플레이북 문법 검사"
    echo "  dry-run        - 드라이런 모드로 실행"
    echo "  deploy         - Next.js 앱 배포"
    echo "  deploy-tags    - 특정 태그만 실행"
    echo "  inventory      - 인벤토리 정보 확인"
    echo "  facts          - 호스트 팩트 수집"
    echo "  ping           - 호스트 연결 테스트"
    echo "  vault-create   - Ansible Vault 파일 생성"
    echo "  vault-edit     - Ansible Vault 파일 편집"
    echo "  galaxy-install - Galaxy 컬렉션 설치"
    echo "  galaxy-list    - 설치된 컬렉션 목록"
    echo "  clean          - 임시 파일 정리"
    echo "  help           - 이 도움말 표시"
    echo ""
}

# 플레이북 문법 검사
check_syntax() {
    print_header "플레이북 문법 검사"
    ansible-playbook playbooks/deploy-nextjs.yml --syntax-check
    print_status "✅ 문법 검사 완료"
}

# 드라이런 모드
dry_run() {
    print_header "드라이런 모드 실행"
    print_warning "실제 변경사항 없이 시뮬레이션만 수행합니다"
    ansible-playbook playbooks/deploy-nextjs.yml --check --diff
}

# 일반 배포
deploy() {
    print_header "Next.js 앱 배포"
    ansible-playbook playbooks/deploy-nextjs.yml
}

# 태그별 배포
deploy_with_tags() {
    echo "사용 가능한 태그:"
    echo "  - namespace"
    echo "  - configmap" 
    echo "  - deployment"
    echo "  - service"
    echo "  - verify"
    echo ""
    read -p "실행할 태그를 입력하세요 (여러 개는 쉼표로 구분): " tags
    
    if [ -z "$tags" ]; then
        print_error "태그를 입력해주세요"
        return 1
    fi
    
    print_header "태그별 배포: $tags"
    ansible-playbook playbooks/deploy-nextjs.yml --tags "$tags"
}

# 인벤토리 정보 확인
show_inventory() {
    print_header "인벤토리 정보"
    echo "📋 호스트 목록:"
    ansible-inventory --list --yaml
    echo ""
    echo "🔍 호스트 그래프:"
    ansible-inventory --graph
}

# 팩트 수집
gather_facts() {
    print_header "호스트 팩트 수집"
    ansible localhost -m ansible.builtin.setup
}

# 연결 테스트
ping_hosts() {
    print_header "호스트 연결 테스트"
    ansible all -m ansible.builtin.ping
}

# Vault 파일 생성
create_vault() {
    read -p "생성할 vault 파일명을 입력하세요 (예: secrets.yml): " filename
    if [ -z "$filename" ]; then
        print_error "파일명을 입력해주세요"
        return 1
    fi
    
    print_header "Ansible Vault 파일 생성: $filename"
    ansible-vault create "$filename"
}

# Vault 파일 편집
edit_vault() {
    read -p "편집할 vault 파일명을 입력하세요: " filename
    if [ -z "$filename" ] || [ ! -f "$filename" ]; then
        print_error "파일이 존재하지 않습니다: $filename"
        return 1
    fi
    
    print_header "Ansible Vault 파일 편집: $filename"
    ansible-vault edit "$filename"
}

# Galaxy 컬렉션 설치
install_galaxy() {
    print_header "Galaxy 컬렉션 설치"
    ansible-galaxy collection install -r requirements.yml --force
    print_status "✅ 컬렉션 설치 완료"
}

# 설치된 컬렉션 목록
list_galaxy() {
    print_header "설치된 Galaxy 컬렉션"
    ansible-galaxy collection list
}

# 임시 파일 정리
clean_temp() {
    print_header "임시 파일 정리"
    
    # Ansible 임시 파일들
    find ~/.ansible/tmp -name "ansible-tmp-*" -type d -exec rm -rf {} + 2>/dev/null || true
    
    # 로컬 임시 파일들
    find . -name "*.retry" -delete 2>/dev/null || true
    find . -name ".ansible" -type d -exec rm -rf {} + 2>/dev/null || true
    
    print_status "✅ 정리 완료"
}

# 고급 명령어들
advanced_commands() {
    print_header "고급 Ansible 명령어들"
    echo ""
    echo "🔍 디버깅 명령어:"
    echo "  # 상세한 로그와 함께 실행"
    echo "  ansible-playbook playbooks/deploy-nextjs.yml -vvv"
    echo ""
    echo "  # 특정 호스트만 대상으로 실행"
    echo "  ansible-playbook playbooks/deploy-nextjs.yml --limit localhost"
    echo ""
    echo "  # 특정 태스크부터 시작"
    echo "  ansible-playbook playbooks/deploy-nextjs.yml --start-at-task=\"배포 상태 확인\""
    echo ""
    echo "🎯 Kubernetes 관련:"
    echo "  # kubectl 명령어 실행"
    echo "  ansible localhost -m kubernetes.core.k8s_info -a \"api_version=v1 kind=Pod namespace=nextjs-sample\""
    echo ""
    echo "📊 성능 측정:"
    echo "  # 프로파일링과 함께 실행"
    echo "  ansible-playbook playbooks/deploy-nextjs.yml --profile"
    echo ""
    echo "🔐 보안:"
    echo "  # Vault 암호화된 변수 사용"
    echo "  ansible-playbook playbooks/deploy-nextjs.yml --ask-vault-pass"
    echo ""
}

# 메인 로직
case "${1:-help}" in
    "check")
        check_syntax
        ;;
    "dry-run")
        dry_run
        ;;
    "deploy")
        deploy
        ;;
    "deploy-tags")
        deploy_with_tags
        ;;
    "inventory")
        show_inventory
        ;;
    "facts")
        gather_facts
        ;;
    "ping")
        ping_hosts
        ;;
    "vault-create")
        create_vault
        ;;
    "vault-edit")
        edit_vault
        ;;
    "galaxy-install")
        install_galaxy
        ;;
    "galaxy-list")
        list_galaxy
        ;;
    "clean")
        clean_temp
        ;;
    "advanced")
        advanced_commands
        ;;
    "help"|*)
        show_help
        ;;
esac
