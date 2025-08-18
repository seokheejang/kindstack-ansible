#!/bin/bash

# Production 환경 설정 스크립트

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "========================================"
echo "Production 환경 설정 시작"
echo "========================================"

# 색깔 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 1. Bridge 서버 Docker 빌드 및 실행
setup_bridge_server() {
    print_status "Bridge 서버 설정 중..."
    
    local bridge_dir="$SCRIPT_DIR/../bridge-server"
    cd "$bridge_dir"
    
    # 기존 컨테이너 정리
    print_status "기존 Bridge 서버 컨테이너 정리 중..."
    docker stop bridge-server 2>/dev/null || true
    docker rm bridge-server 2>/dev/null || true
    
    # Docker 이미지 빌드
    print_status "Bridge 서버 Docker 이미지 빌드 중..."
    docker build -t bridge-server:latest .
    
    if [ $? -ne 0 ]; then
        print_error "Bridge 서버 Docker 이미지 빌드 실패"
        return 1
    fi
    
    # Docker 컨테이너 실행
    print_status "Bridge 서버 Docker 컨테이너 시작 중..."
    docker run -d \
        --name bridge-server \
        -p 8080:8080 \
        -e HOST_HOME_DIR="$HOME" \
        -v "$bridge_dir":/app/data \
        -v /var/run/docker.sock:/var/run/docker.sock \
        bridge-server:latest
    
    if [ $? -ne 0 ]; then
        print_error "Bridge 서버 컨테이너 시작 실패"
        return 1
    fi
    
    # 서버 시작 대기
    print_status "Bridge 서버 시작 대기 중..."
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -s http://localhost:8080/api/v1/health > /dev/null 2>&1; then
            print_success "Bridge 서버가 성공적으로 시작되었습니다 (Docker 컨테이너)"
            return 0
        fi
        
        sleep 2
        attempt=$((attempt + 1))
        echo -n "."
    done
    
    echo ""
    print_error "Bridge 서버 시작 실패 - 타임아웃"
    print_error "컨테이너 로그를 확인하세요: docker logs bridge-server"
    return 1
}

# 2. Ansible Runner 이미지 빌드
setup_ansible_runner() {
    print_status "Ansible Runner 이미지 빌드 중..."
    
    # PROJECT_ROOT는 이미 production-deploy 디렉토리이므로 그대로 사용
    cd "$PROJECT_ROOT"
    
    # Docker 이미지 빌드
    docker build -t ansible-runner:latest .
    
    if [ $? -eq 0 ]; then
        print_success "Ansible Runner 이미지 빌드 완료"
    else
        print_error "Ansible Runner 이미지 빌드 실패"
        return 1
    fi
}

# 3. 환경 검증
verify_environment() {
    print_status "환경 검증 중..."
    
    # 필수 도구 확인
    local tools=("docker" "kubectl" "curl")
    for tool in "${tools[@]}"; do
        if command -v $tool &> /dev/null; then
            print_success "$tool 설치됨"
        else
            print_error "$tool이 설치되지 않았습니다"
            return 1
        fi
    done
    
    # Go는 Docker 빌드에서 사용되므로 선택사항으로 변경
    if command -v go &> /dev/null; then
        print_success "go 설치됨 (로컬 개발용)"
    else
        print_warning "go가 설치되지 않았습니다 (Docker 빌드만 사용)"
    fi
    
    # Kubernetes 클러스터 확인
    if kubectl cluster-info &> /dev/null; then
        print_success "Kubernetes 클러스터 접근 가능"
    else
        print_warning "Kubernetes 클러스터에 접근할 수 없습니다"
        print_warning "Kind 클러스터를 시작하려면 다음 명령어를 실행하세요:"
        print_warning "  cd $PROJECT_ROOT/../simple-test && ./scripts/setup.sh"
    fi
    
    # Docker 상태 확인
    if docker info &> /dev/null; then
        print_success "Docker 서비스 실행 중"
    else
        print_error "Docker 서비스가 실행되지 않고 있습니다"
        return 1
    fi
}

# 4. 데모 배포 실행
run_demo_deployment() {
    print_status "데모 배포 실행 중..."
    
    # 배포 요청 데이터
    local deployment_data='{
        "name": "demo-app",
        "docker_image": "nginx:alpine",
        "domain": "demo.local",
        "env_config": "DEMO=true"
    }'
    
    # Bridge 서버로 배포 요청
    local response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$deployment_data" \
        http://localhost:8080/api/v1/deployments)
    
    if echo "$response" | grep -q "deployment"; then
        print_success "데모 배포 요청이 성공적으로 전송되었습니다"
        echo "응답: $response"
        
        # 배포 상태 모니터링
        print_status "배포 상태 모니터링 시작..."
        print_status "다음 명령어로 배포 상태를 확인할 수 있습니다:"
        echo "  curl -s http://localhost:8080/api/v1/deployments | jq"
    else
        print_error "데모 배포 요청 실패"
        echo "응답: $response"
        return 1
    fi
}

# 5. 정리 함수 (EXIT 트랩용 - 간단한 정리만)
cleanup() {
    # Bridge 서버 Docker 컨테이너 종료 (EXIT 트랩에서만 실행)
    docker stop bridge-server 2>/dev/null || true
}

# 6. 완전 정리 함수 (사용자가 명시적으로 호출)
full_cleanup() {
    print_status "전체 정리 작업 실행 중..."
    
    # cleanup-production.sh 스크립트 실행
    local cleanup_script="$SCRIPT_DIR/cleanup-production.sh"
    if [ -f "$cleanup_script" ]; then
        print_status "cleanup-production.sh 실행 중..."
        "$cleanup_script" --all
    else
        print_error "cleanup-production.sh를 찾을 수 없습니다: $cleanup_script"
        return 1
    fi
    
    print_success "전체 정리 작업 완료!"
}

# 메인 실행 흐름
main() {
    # 인자 처리
    case "${1:-all}" in
        "bridge")
            setup_bridge_server
            ;;
        "runner")
            setup_ansible_runner
            ;;
        "verify")
            verify_environment
            ;;
        "demo")
            run_demo_deployment
            ;;
        "cleanup")
            full_cleanup
            ;;
        "all")
            verify_environment
            setup_bridge_server
            setup_ansible_runner
            echo ""
            print_success "Production 환경 설정 완료!"
            echo ""
            print_status "다음 단계:"
            echo "1. 데모 배포: $0 demo"
            echo "2. 배포 상태 확인: curl -s http://localhost:8080/api/v1/deployments | jq"
            echo "3. 정리: $0 cleanup"
            echo ""
            ;;
        *)
            echo "사용법: $0 [bridge|runner|verify|demo|cleanup|all]"
            echo ""
            echo "  bridge  - Bridge 서버만 설정"
            echo "  runner  - Ansible Runner 이미지만 빌드" 
            echo "  verify  - 환경 검증만 수행"
            echo "  demo    - 데모 배포 실행"
            echo "  cleanup - 정리 작업"
            echo "  all     - 전체 설정 (기본값)"
            exit 1
            ;;
    esac
}

# 스크립트 종료 시 정리
trap cleanup EXIT

# 메인 함수 실행
main "$@"
