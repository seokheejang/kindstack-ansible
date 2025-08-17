#!/bin/bash

# 테스트 환경 정리 스크립트

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "🧹 테스트 환경을 정리합니다..."

# 사용자 확인
read -p "정말로 모든 리소스를 삭제하시겠습니까? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "취소되었습니다."
    exit 0
fi

# 1. Kubernetes 네임스페이스 삭제
print_status "Kubernetes 리소스를 삭제합니다..."
namespaces=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep -E '^nextjs-|^sample-' || true)

if [ -n "$namespaces" ]; then
    for ns in $namespaces; do
        print_status "네임스페이스 '$ns' 삭제 중..."
        kubectl delete namespace "$ns" --ignore-not-found=true
    done
else
    print_warning "삭제할 네임스페이스가 없습니다."
fi

# 2. Kind 클러스터 삭제 여부 확인
read -p "Kind 클러스터도 삭제하시겠습니까? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Kind 클러스터를 삭제합니다..."
    kind delete cluster --name kind
    print_status "✅ Kind 클러스터가 삭제되었습니다."
fi

# 3. LocalStack 컨테이너 정지 여부 확인
read -p "LocalStack 컨테이너를 정지하시겠습니까? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "LocalStack 컨테이너를 정지합니다..."
    docker-compose down
    print_status "✅ LocalStack 컨테이너가 정지되었습니다."
fi

# 4. Docker 이미지 정리 여부 확인
read -p "사용하지 않는 Docker 이미지를 정리하시겠습니까? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Docker 이미지를 정리합니다..."
    docker system prune -f
    print_status "✅ Docker 이미지 정리가 완료되었습니다."
fi

print_status "🎉 정리가 완료되었습니다!"
echo ""
echo "다시 시작하려면:"
echo "  ./scripts/setup.sh"
