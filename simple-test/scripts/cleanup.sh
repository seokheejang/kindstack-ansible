#!/bin/bash

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 함수 정의
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
    echo "  --all, -a          모든 것을 완전히 정리 (Kind 클러스터, LocalStack 포함)"
    echo "  --kubernetes, -k   Kubernetes 리소스만 정리"
    echo "  --localstack, -l   LocalStack만 정리"
    echo "  --help, -h         이 도움말 표시"
    echo ""
    echo "예시:"
    echo "  $0                 # 기본 정리 (K8s + LocalStack)"
    echo "  $0 --all           # 완전 정리 (Kind 클러스터까지 삭제)"
    echo "  $0 --kubernetes    # Kubernetes 리소스만 정리"
    echo "  $0 --localstack    # LocalStack만 재시작"
}

# Kubernetes 리소스 정리
cleanup_kubernetes() {
    print_header "Kubernetes 리소스 정리"
    
    # 1. 애플리케이션 네임스페이스 삭제
    print_status "애플리케이션 네임스페이스 삭제 중..."
    kubectl delete namespace nextjs-sample --ignore-not-found=true
    
    # 2. Ingress Controller 삭제
    print_status "NGINX Ingress Controller 삭제 중..."
    kubectl delete namespace ingress-nginx --ignore-not-found=true
    
    # 3. 임시 파일 정리
    print_status "임시 파일 정리 중..."
    rm -f /tmp/nextjs-*.yaml
    
    # 4. 리소스 삭제 대기
    print_status "리소스 삭제 완료 대기 중..."
    sleep 15
    
    print_success "Kubernetes 리소스 정리 완료"
}

# LocalStack 정리
cleanup_localstack() {
    print_header "LocalStack 정리"
    
    print_status "LocalStack 컨테이너 중지 및 삭제 중..."
    docker-compose down
    
    # LocalStack 볼륨 정리 (필요시)
    print_status "LocalStack 볼륨 정리 중..."
    docker volume prune -f
    
    print_status "LocalStack 재시작 중..."
    docker-compose up -d
    
    # LocalStack 준비 대기
    print_status "LocalStack 준비 대기 중..."
    sleep 10
    
    # LocalStack 상태 확인
    if curl -s http://localhost:4566/_localstack/health > /dev/null; then
        print_success "LocalStack 재시작 완료"
    else
        print_warning "LocalStack 상태 확인 실패 - 수동으로 확인해주세요"
    fi
}

# Kind 클러스터 완전 삭제
cleanup_kind() {
    print_header "Kind 클러스터 완전 삭제"
    
    print_status "Kind 클러스터 삭제 중..."
    kind delete cluster --name kind
    
    print_status "Kind 클러스터 재생성 중..."
    if [ -f "kind-config.yaml" ]; then
        kind create cluster --name kind --config kind-config.yaml
        print_success "Ingress 지원 Kind 클러스터 재생성 완료"
    else
        kind create cluster --name kind
        print_success "기본 Kind 클러스터 재생성 완료"
    fi
}

# 포트 사용 중인 프로세스 정리
cleanup_ports() {
    print_header "포트 사용 중인 프로세스 정리"
    
    # 8080 포트 정리 (포트 포워딩)
    print_status "포트 포워딩 프로세스 정리 중..."
    pkill -f "kubectl port-forward" 2>/dev/null || true
    
    # 백그라운드 작업 정리
    jobs -p | xargs -r kill 2>/dev/null || true
    
    print_success "포트 정리 완료"
}

# 전체 상태 확인
check_status() {
    print_header "환경 상태 확인"
    
    echo "📊 현재 상태:"
    echo ""
    
    # Docker 상태
    echo "🐳 Docker:"
    docker ps --filter "name=kind\|localstack" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "  Docker가 실행되지 않음"
    echo ""
    
    # Kubernetes 상태
    echo "☸️  Kubernetes:"
    if kubectl cluster-info --context kind-kind &> /dev/null; then
        echo "  ✅ Kind 클러스터: 실행 중"
        echo "  📦 네임스페이스:"
        kubectl get namespaces 2>/dev/null | grep -E "(nextjs-sample|ingress-nginx)" || echo "      정리됨"
    else
        echo "  ❌ Kind 클러스터: 실행되지 않음"
    fi
    echo ""
    
    # LocalStack 상태
    echo "☁️  LocalStack:"
    if curl -s http://localhost:4566/_localstack/health > /dev/null 2>&1; then
        echo "  ✅ LocalStack: 실행 중"
    else
        echo "  ❌ LocalStack: 실행되지 않음"
    fi
    echo ""
}

# 메인 로직
main() {
    case "$1" in
        --all|-a)
            print_header "완전 정리 시작 (Kind 클러스터 포함)"
            cleanup_ports
            cleanup_kubernetes
            cleanup_localstack
            cleanup_kind
            ;;
        --kubernetes|-k)
            print_header "Kubernetes 리소스만 정리"
            cleanup_ports
            cleanup_kubernetes
            ;;
        --localstack|-l)
            print_header "LocalStack만 정리"
            cleanup_localstack
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        "")
            print_header "기본 정리 시작 (K8s + LocalStack)"
            cleanup_ports
            cleanup_kubernetes
            cleanup_localstack
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
    echo "  make deploy-full"
    echo "  또는"
    echo "  ansible-playbook playbooks/deploy-full-stack.yml"
}

# 스크립트 실행
main "$@"