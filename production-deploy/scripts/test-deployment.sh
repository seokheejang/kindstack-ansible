#!/bin/bash

# 배포 테스트 스크립트

set -e

BRIDGE_URL=${BRIDGE_SERVER_URL:-"http://localhost:8080"}

echo "========================================"
echo "배포 테스트 시작"
echo "Bridge Server: $BRIDGE_URL"
echo "========================================"

# 색깔 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 1. Bridge 서버 상태 확인
check_bridge_server() {
    print_status "Bridge 서버 상태 확인 중..."
    
    local health_response=$(curl -s "$BRIDGE_URL/api/v1/health" || echo "error")
    
    if echo "$health_response" | grep -q "healthy"; then
        print_success "Bridge 서버가 정상 작동 중입니다"
        echo "응답: $health_response"
    else
        print_error "Bridge 서버에 접근할 수 없습니다"
        print_error "서버를 시작하려면: cd ../scripts && ./setup-production.sh bridge"
        exit 1
    fi
}

# 2. 새 배포 생성
create_deployment() {
    print_status "새 배포 생성 중..."
    
    local app_name="test-app-$(date +%s)"
    local deployment_data='{
        "name": "'$app_name'",
        "docker_image": "nginx:alpine",
        "domain": "test.local",
        "env_config": "TEST=true"
    }'
    
    local response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$deployment_data" \
        "$BRIDGE_URL/api/v1/deployments")
    
    if echo "$response" | grep -q "deployment"; then
        print_success "배포 생성 성공: $app_name"
        
        # 배포 ID 추출
        DEPLOYMENT_ID=$(echo "$response" | grep -o '"id":[0-9]*' | cut -d: -f2)
        echo "배포 ID: $DEPLOYMENT_ID"
        return 0
    else
        print_error "배포 생성 실패"
        echo "응답: $response"
        return 1
    fi
}

# 3. 배포 상태 모니터링
monitor_deployment() {
    local deployment_id=$1
    local timeout=300  # 5분 타임아웃
    local elapsed=0
    local interval=10
    
    print_status "배포 상태 모니터링 시작 (ID: $deployment_id)"
    
    while [ $elapsed -lt $timeout ]; do
        local status_response=$(curl -s "$BRIDGE_URL/api/v1/deployments/$deployment_id")
        local deployment_status=$(echo "$status_response" | grep -o '"status":"[^"]*' | cut -d'"' -f4)
        
        case "$deployment_status" in
            "pending")
                print_status "배포 대기 중... ($elapsed/${timeout}s)"
                ;;
            "running")
                print_status "배포 실행 중... ($elapsed/${timeout}s)"
                ;;
            "completed")
                print_success "배포 완료!"
                return 0
                ;;
            "failed")
                print_error "배포 실패!"
                show_deployment_steps $deployment_id
                return 1
                ;;
            *)
                print_status "알 수 없는 상태: $deployment_status ($elapsed/${timeout}s)"
                ;;
        esac
        
        sleep $interval
        elapsed=$((elapsed + interval))
    done
    
    print_error "배포 타임아웃 (${timeout}초 경과)"
    return 1
}

# 4. 배포 단계별 상태 출력
show_deployment_steps() {
    local deployment_id=$1
    
    print_status "배포 단계별 상태:"
    
    local steps_response=$(curl -s "$BRIDGE_URL/api/v1/deployments/$deployment_id/steps")
    echo "$steps_response" | jq -r '.steps[] | "  \(.step_name): \(.status) - \(.message // "진행중")"' 2>/dev/null || echo "$steps_response"
}

# 5. 전체 배포 목록 출력
list_deployments() {
    print_status "전체 배포 목록:"
    
    local deployments_response=$(curl -s "$BRIDGE_URL/api/v1/deployments")
    echo "$deployments_response" | jq -r '.deployments[] | "  ID: \(.id), Name: \(.name), Status: \(.status), Domain: \(.domain)"' 2>/dev/null || echo "$deployments_response"
}

# 6. 콜백 테스트
test_callback() {
    local deployment_id=$1
    
    print_status "콜백 API 테스트 중..."
    
    local callback_data='{
        "deployment_id": '$deployment_id',
        "step_name": "test_step",
        "status": "running",
        "message": "테스트 콜백"
    }'
    
    local response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$callback_data" \
        "$BRIDGE_URL/api/v1/infra/callback")
    
    if echo "$response" | grep -q "성공적으로"; then
        print_success "콜백 테스트 성공"
    else
        print_error "콜백 테스트 실패"
        echo "응답: $response"
    fi
}

# 메인 실행 흐름
main() {
    case "${1:-full}" in
        "health")
            check_bridge_server
            ;;
        "create")
            check_bridge_server
            create_deployment
            ;;
        "list")
            check_bridge_server
            list_deployments
            ;;
        "monitor")
            if [ -z "$2" ]; then
                print_error "배포 ID를 지정해주세요: $0 monitor <deployment_id>"
                exit 1
            fi
            check_bridge_server
            monitor_deployment "$2"
            show_deployment_steps "$2"
            ;;
        "callback")
            if [ -z "$2" ]; then
                print_error "배포 ID를 지정해주세요: $0 callback <deployment_id>"
                exit 1
            fi
            check_bridge_server
            test_callback "$2"
            ;;
        "full")
            check_bridge_server
            create_deployment
            if [ $? -eq 0 ] && [ -n "$DEPLOYMENT_ID" ]; then
                test_callback "$DEPLOYMENT_ID"
                monitor_deployment "$DEPLOYMENT_ID"
                show_deployment_steps "$DEPLOYMENT_ID"
            fi
            list_deployments
            ;;
        *)
            echo "사용법: $0 [health|create|list|monitor|callback|full] [deployment_id]"
            echo ""
            echo "  health           - Bridge 서버 상태 확인"
            echo "  create           - 새 배포 생성"
            echo "  list             - 전체 배포 목록"
            echo "  monitor <id>     - 특정 배포 모니터링"
            echo "  callback <id>    - 콜백 API 테스트"
            echo "  full             - 전체 테스트 (기본값)"
            exit 1
            ;;
    esac
}

# 메인 함수 실행
main "$@"
