#!/bin/bash

# Next.js 앱 배포 스크립트

set -e

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

echo "🚀 Next.js 앱을 Kind 클러스터에 배포합니다..."

# 현재 디렉토리가 프로젝트 루트인지 확인
if [ ! -f "ansible.cfg" ]; then
    echo "❌ 프로젝트 루트 디렉토리에서 실행해주세요."
    exit 1
fi

# 환경 설정 스크립트 실행
if [ -f "scripts/setup.sh" ]; then
    print_status "환경 설정을 확인합니다..."
    ./scripts/setup.sh
fi

# Ansible 플레이북 실행
print_status "Ansible 플레이북을 실행합니다..."
ansible-playbook playbooks/deploy-nextjs.yml

print_status "🎉 배포가 완료되었습니다!"
echo ""
echo "📋 유용한 명령어들:"
echo "  # Pod 상태 확인"
echo " c"
echo ""
echo "  # 서비스 확인"
echo "  kubectl get svc -n nextjs-sample"
echo ""
echo "  # 로그 확인"
echo "  kubectl logs -f deployment/nextjs-sample-deployment -n nextjs-sample"
echo ""
echo "  # 앱 접속"
echo "  open http://localhost:30080"
echo ""
echo "  # 정리"
echo "  kubectl delete namespace nextjs-sample"
