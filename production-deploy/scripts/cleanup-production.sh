#!/bin/bash

# Production 환경 정리 스크립트

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_header() {
    echo -e "${CYAN}🧹 $1${NC}"
}

# 사용법 출력
show_usage() {
    echo "사용법: $0 [옵션]"
    echo ""
    echo "옵션:"
    echo "  --all, -a          모든 것을 완전히 정리 (Bridge 서버, 컨테이너, K8s, DB)"
    echo "  --bridge, -b       Bridge 서버만 정리"
    echo "  --containers, -c   Ansible Runner 컨테이너만 정리"
    echo "  --kubernetes, -k   Kubernetes 리소스만 정리"
    echo "  --database, -d     Bridge 서버 데이터베이스만 정리"
    echo "  --help, -h         이 도움말 표시"
    echo ""
    echo "예시:"
    echo "  $0                 # 기본 정리 (컨테이너 + K8s)"
    echo "  $0 --all           # 완전 정리 (모든 것)"
    echo "  $0 --bridge        # Bridge 서버만 정리"
    echo "  $0 --containers    # Ansible Runner 컨테이너만 정리"
}

# Bridge 서버 정리
cleanup_bridge_server() {
    print_header "Bridge 서버 정리"
    
    # Bridge 서버 Docker 컨테이너 정리
    print_status "Bridge 서버 Docker 컨테이너 정리 중..."
    
    # 이름으로 컨테이너 정리 (더 안전)
    if docker ps -q --filter "name=bridge-server" | grep -q .; then
        print_status "실행 중인 bridge-server 컨테이너 중지 중..."
        docker stop bridge-server
        print_success "bridge-server 컨테이너 중지 완료"
    fi
    
    if docker ps -aq --filter "name=bridge-server" | grep -q .; then
        print_status "bridge-server 컨테이너 삭제 중..."
        docker rm bridge-server
        print_success "bridge-server 컨테이너 삭제 완료"
    fi
    
    # 이미지로도 정리 (혹시 다른 이름으로 실행된 경우)
    local containers_by_image=$(docker ps -aq --filter "ancestor=bridge-server:latest" 2>/dev/null || true)
    if [ -n "$containers_by_image" ]; then
        print_status "bridge-server 이미지 기반 컨테이너 정리 중..."
        echo $containers_by_image | xargs docker stop 2>/dev/null || true
        echo $containers_by_image | xargs docker rm 2>/dev/null || true
        print_success "bridge-server 이미지 기반 컨테이너 정리 완료"
    fi
    
    # 포트 8080을 사용하는 프로세스 확인 (혹시나 남은 프로세스)
    print_status "포트 8080 사용 프로세스 확인 중..."
    local bridge_pids=$(lsof -ti:8080 2>/dev/null || true)
    if [ -n "$bridge_pids" ]; then
        print_warning "포트 8080을 사용하는 프로세스 발견: $bridge_pids"
        echo $bridge_pids | xargs kill 2>/dev/null || true
        print_success "포트 8080 프로세스 정리 완료"
    fi
    
    print_success "Bridge 서버 정리 완료"
}

# Ansible Runner 컨테이너 정리
cleanup_ansible_containers() {
    print_header "Ansible Runner 컨테이너 정리"
    
    # 실행 중인 Ansible Runner 컨테이너 정리
    print_status "실행 중인 Ansible Runner 컨테이너 찾는 중..."
    local running_containers=$(docker ps -q --filter "name=ansible-runner-*" 2>/dev/null || true)
    if [ -n "$running_containers" ]; then
        print_status "실행 중인 컨테이너 중지 중..."
        echo $running_containers | xargs docker stop
        print_success "실행 중인 컨테이너 중지 완료"
    fi
    
    # 모든 Ansible Runner 컨테이너 삭제
    print_status "모든 Ansible Runner 컨테이너 삭제 중..."
    local all_containers=$(docker ps -aq --filter "name=ansible-runner-*" 2>/dev/null || true)
    if [ -n "$all_containers" ]; then
        echo $all_containers | xargs docker rm -f
        print_success "모든 Ansible Runner 컨테이너 삭제 완료"
    fi
    
    # Ansible Runner 이미지도 정리 (선택적)
    print_status "사용하지 않는 Ansible Runner 이미지 정리 중..."
    docker image prune -f --filter "label=ansible-runner" 2>/dev/null || true
    
    print_success "Ansible Runner 컨테이너 정리 완료"
}

# Kubernetes 리소스 정리 (Production 배포된 것들)
cleanup_kubernetes() {
    print_header "Kubernetes 리소스 정리"
    
    # Production으로 배포된 네임스페이스들 찾기
    print_status "Production 배포 네임스페이스 찾는 중..."
    local namespaces=$(kubectl get namespaces -o name 2>/dev/null | grep -E "sample-app|demo-app|test-app" || true)
    
    if [ -n "$namespaces" ]; then
        print_status "다음 네임스페이스들을 삭제합니다:"
        echo "$namespaces" | sed 's/namespace\//  - /'
        echo "$namespaces" | sed 's/namespace\///' | xargs kubectl delete namespace --ignore-not-found=true
        print_success "Production 네임스페이스 정리 완료"
    else
        print_status "정리할 Production 네임스페이스가 없습니다"
    fi
    
    # Ingress Controller 확인 및 정리 (필요시)
    print_status "Ingress Controller 상태 확인 중..."
    if kubectl get namespace ingress-nginx >/dev/null 2>&1; then
        local ingress_resources=$(kubectl get pods -n ingress-nginx 2>/dev/null | wc -l)
        if [ $ingress_resources -gt 1 ]; then
            print_warning "Ingress Controller가 설치되어 있습니다. 삭제하려면 수동으로 실행하세요:"
            print_warning "kubectl delete namespace ingress-nginx"
        fi
    fi
    
    # 리소스 삭제 대기
    print_status "리소스 삭제 완료 대기 중..."
    sleep 10
    
    print_success "Kubernetes 리소스 정리 완료"
}

# Bridge 서버 데이터베이스 정리
cleanup_database() {
    print_header "Bridge 서버 데이터베이스 정리"
    
    local bridge_dir="$SCRIPT_DIR/../bridge-server"
    
    print_status "SQLite 데이터베이스 파일 삭제 중..."
    rm -f "$bridge_dir/bridge.db"
    rm -f "$bridge_dir/bridge-server.log"
    
    # Docker 볼륨에서도 정리 (컨테이너가 실행 중이지 않을 때)
    if ! docker ps --filter "name=bridge-server" | grep -q bridge-server; then
        rm -f "$bridge_dir"/*.db 2>/dev/null || true
        rm -f "$bridge_dir"/*.log 2>/dev/null || true
    fi
    
    print_success "데이터베이스 정리 완료"
}

# Docker 네트워크 및 볼륨 정리
cleanup_docker_resources() {
    print_header "Docker 리소스 정리"
    
    print_status "사용하지 않는 Docker 네트워크 정리 중..."
    docker network prune -f 2>/dev/null || true
    
    print_status "사용하지 않는 Docker 볼륨 정리 중..."
    docker volume prune -f 2>/dev/null || true
    
    print_status "사용하지 않는 Docker 이미지 정리 중..."
    docker image prune -f 2>/dev/null || true
    
    print_success "Docker 리소스 정리 완료"
}

# 전체 상태 확인
check_status() {
    print_header "Production 환경 상태 확인"
    
    echo "📊 현재 상태:"
    echo ""
    
    # Bridge 서버 상태
    echo "🌉 Bridge 서버:"
    local bridge_container_status=$(docker ps --filter "name=bridge-server" --format "{{.Status}}" 2>/dev/null || echo "")
    if [ -n "$bridge_container_status" ]; then
        echo "  🐳 Docker 컨테이너: 실행 중 ($bridge_container_status)"
        if curl -s http://localhost:8080/api/v1/health >/dev/null 2>&1; then
            echo "  ✅ API 서버: 응답 중 (http://localhost:8080)"
        else
            echo "  ⚠️  API 서버: 시작 중 또는 문제 발생"
        fi
    else
        echo "  ❌ Docker 컨테이너: 정지됨"
    fi
    echo ""
    
    # Ansible Runner 컨테이너 상태
    echo "🐳 Ansible Runner 컨테이너:"
    local containers=$(docker ps --filter "name=ansible-runner-*" --format "table {{.Names}}\t{{.Status}}" 2>/dev/null | tail -n +2)
    if [ -n "$containers" ]; then
        echo "$containers" | sed 's/^/  /'
    else
        echo "  ✅ 실행 중인 컨테이너 없음"
    fi
    echo ""
    
    # Kubernetes 상태
    echo "☸️  Kubernetes:"
    if kubectl cluster-info >/dev/null 2>&1; then
        echo "  ✅ 클러스터: 접근 가능"
        echo "  📦 Production 네임스페이스:"
        local prod_ns=$(kubectl get namespaces -o name 2>/dev/null | grep -E "sample-app|demo-app|test-app" | sed 's/namespace\//    - /' || echo "    정리됨")
        echo "$prod_ns"
    else
        echo "  ❌ 클러스터: 접근 불가"
    fi
    echo ""
    
    # 데이터베이스 상태
    echo "💾 데이터베이스:"
    local bridge_dir="$SCRIPT_DIR/../bridge-server"
    if [ -f "$bridge_dir/bridge.db" ]; then
        local db_size=$(ls -lh "$bridge_dir/bridge.db" | awk '{print $5}')
        echo "  📁 bridge.db: 존재함 ($db_size)"
    else
        echo "  ✅ bridge.db: 정리됨"
    fi
    echo ""
}

# 메인 로직
main() {
    case "$1" in
        --all|-a)
            print_header "완전 정리 시작 (모든 리소스)"
            cleanup_bridge_server
            cleanup_ansible_containers
            cleanup_kubernetes
            cleanup_database
            cleanup_docker_resources
            ;;
        --bridge|-b)
            print_header "Bridge 서버만 정리"
            cleanup_bridge_server
            ;;
        --containers|-c)
            print_header "Ansible Runner 컨테이너만 정리"
            cleanup_ansible_containers
            ;;
        --kubernetes|-k)
            print_header "Kubernetes 리소스만 정리"
            cleanup_kubernetes
            ;;
        --database|-d)
            print_header "데이터베이스만 정리"
            cleanup_database
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        "")
            print_header "기본 정리 시작 (컨테이너 + K8s)"
            cleanup_ansible_containers
            cleanup_kubernetes
            ;;
        *)
            print_error "알 수 없는 옵션: $1"
            show_usage
            exit 1
            ;;
    esac
    
    echo ""
    print_success "정리 작업 완료!"
    echo ""
    check_status
    
    echo ""
    print_status "이제 새로운 배포를 시작할 수 있습니다:"
    echo "  ./scripts/setup-production.sh"
    echo "  또는"
    echo "  ./scripts/test-deployment.sh full"
}

# 스크립트 실행
main "$@"
