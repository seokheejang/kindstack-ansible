#!/bin/bash

# Ansible 로컬 테스트 환경 설정 스크립트

set -e

echo "🚀 Ansible 로컬 테스트 환경을 설정합니다..."

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 함수 정의
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 0. OS 감지
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/lsb-release ] || [ -f /etc/debian_version ]; then
            echo "ubuntu"
        elif [ -f /etc/redhat-release ] || [ -f /etc/centos-release ]; then
            echo "centos"
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

OS=$(detect_os)
print_status "감지된 OS: $OS"

# 1. 필수 도구 설치 확인 및 자동 설치
print_status "필수 도구 설치 상태를 확인합니다..."

# Ansible 설치 확인 및 자동 설치
if ! command -v ansible &> /dev/null; then
    print_warning "Ansible이 설치되지 않았습니다. 자동으로 설치합니다..."
    
    case $OS in
        "ubuntu")
            print_status "Ubuntu에서 Ansible을 설치합니다..."
            sudo apt update
            sudo apt install -y software-properties-common
            sudo add-apt-repository --yes --update ppa:ansible/ansible
            sudo apt install -y ansible
            ;;
        "centos")
            print_status "CentOS에서 Ansible을 설치합니다..."
            sudo yum install -y epel-release
            sudo yum install -y ansible
            ;;
        "macos")
            print_status "macOS에서 Ansible을 설치합니다..."
            if command -v brew &> /dev/null; then
                brew install ansible
            else
                print_warning "Homebrew를 사용할 수 없습니다. pip3로 설치합니다..."
                pip3 install --user ansible
                export PATH="$HOME/.local/bin:$PATH"
            fi
            ;;
        *)
            print_warning "지원되지 않는 OS입니다. pip3로 설치를 시도합니다..."
            pip3 install --user ansible
            export PATH="$HOME/.local/bin:$PATH"
            ;;
    esac
    
    # 설치 후 재확인
    if ! command -v ansible &> /dev/null; then
        print_error "Ansible 설치에 실패했습니다."
        echo "수동 설치 방법:"
        echo "  Ubuntu: sudo apt install ansible"
        echo "  CentOS: sudo yum install ansible"
        echo "  macOS: brew install ansible"
        echo "  기타: pip3 install --user ansible"
        exit 1
    fi
    print_status "✅ Ansible이 성공적으로 설치되었습니다."
else
    print_status "✅ Ansible이 이미 설치되어 있습니다."
fi

# kubectl 설치 확인 및 자동 설치
if ! command -v kubectl &> /dev/null; then
    print_warning "kubectl이 설치되지 않았습니다. 자동으로 설치합니다..."
    
    case $OS in
        "ubuntu")
            print_status "Ubuntu에서 kubectl을 설치합니다..."
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
            sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
            rm kubectl
            ;;
        "centos")
            print_status "CentOS에서 kubectl을 설치합니다..."
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
            sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
            rm kubectl
            ;;
        "macos")
            print_status "macOS에서 kubectl을 설치합니다..."
            if command -v brew &> /dev/null; then
                brew install kubectl
            else
                curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
                chmod +x kubectl
                sudo mv kubectl /usr/local/bin/
            fi
            ;;
        *)
            print_error "kubectl 자동 설치를 지원하지 않는 OS입니다."
            echo "수동 설치: https://kubernetes.io/docs/tasks/tools/"
            exit 1
            ;;
    esac
    print_status "✅ kubectl이 성공적으로 설치되었습니다."
else
    print_status "✅ kubectl이 이미 설치되어 있습니다."
fi

# kind 설치 확인 및 자동 설치
if ! command -v kind &> /dev/null; then
    print_warning "kind가 설치되지 않았습니다. 자동으로 설치합니다..."
    
    case $OS in
        "ubuntu"|"centos"|"linux")
            print_status "Linux에서 kind를 설치합니다..."
            curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
            chmod +x ./kind
            sudo mv ./kind /usr/local/bin/kind
            ;;
        "macos")
            print_status "macOS에서 kind를 설치합니다..."
            if command -v brew &> /dev/null; then
                brew install kind
            else
                curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-darwin-amd64
                chmod +x ./kind
                sudo mv ./kind /usr/local/bin/kind
            fi
            ;;
        *)
            print_error "kind 자동 설치를 지원하지 않는 OS입니다."
            echo "수동 설치: https://kind.sigs.k8s.io/docs/user/quick-start/"
            exit 1
            ;;
    esac
    print_status "✅ kind가 성공적으로 설치되었습니다."
else
    print_status "✅ kind가 이미 설치되어 있습니다."
fi

# Docker 설치 확인
if ! command -v docker &> /dev/null; then
    print_warning "Docker가 설치되지 않았습니다."
    
    case $OS in
        "ubuntu")
            print_status "Ubuntu에서 Docker를 설치합니다..."
            sudo apt update
            sudo apt install -y ca-certificates curl gnupg lsb-release
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            sudo apt update
            sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            sudo usermod -aG docker $USER
            print_warning "Docker 그룹에 추가되었습니다. 로그아웃 후 다시 로그인하거나 'newgrp docker'를 실행하세요."
            ;;
        "centos")
            print_status "CentOS에서 Docker를 설치합니다..."
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            sudo systemctl start docker
            sudo systemctl enable docker
            sudo usermod -aG docker $USER
            print_warning "Docker 그룹에 추가되었습니다. 로그아웃 후 다시 로그인하거나 'newgrp docker'를 실행하세요."
            ;;
        "macos")
            print_error "macOS에서는 Docker Desktop을 수동으로 설치해야 합니다."
            echo "다운로드: https://docs.docker.com/desktop/mac/install/"
            exit 1
            ;;
        *)
            print_error "Docker 자동 설치를 지원하지 않는 OS입니다."
            echo "수동 설치: https://docs.docker.com/get-docker/"
            exit 1
            ;;
    esac
    print_status "✅ Docker가 성공적으로 설치되었습니다."
else
    print_status "✅ Docker가 이미 설치되어 있습니다."
fi

print_status "✅ 모든 필수 도구가 설치되어 있습니다."

# 2. Ansible 컬렉션 설치
print_status "Ansible 컬렉션을 설치합니다..."
ansible-galaxy collection install -r requirements.yml --force

# 3. Kind 클러스터 확인/생성
print_status "Kind 클러스터 상태를 확인합니다..."
if ! kubectl cluster-info --context kind-kind &> /dev/null; then
    print_warning "Kind 클러스터가 없습니다. 새로 생성합니다..."
    kind create cluster --name kind
    print_status "✅ Kind 클러스터가 생성되었습니다."
else
    print_status "✅ Kind 클러스터가 이미 실행 중입니다."
fi

# 4. LocalStack 확인/시작
print_status "LocalStack 상태를 확인합니다..."
if ! curl -s http://localhost:4566/health &> /dev/null; then
    print_warning "LocalStack이 실행되지 않았습니다. Docker Compose로 시작합니다..."
    docker-compose up -d
    
    # LocalStack이 완전히 시작될 때까지 대기
    echo "LocalStack이 시작될 때까지 대기 중..."
    timeout=60
    counter=0
    while ! curl -s http://localhost:4566/health &> /dev/null; do
        sleep 2
        counter=$((counter + 2))
        if [ $counter -ge $timeout ]; then
            print_error "LocalStack 시작 시간이 초과되었습니다."
            exit 1
        fi
        echo -n "."
    done
    echo ""
    print_status "✅ LocalStack이 시작되었습니다."
else
    print_status "✅ LocalStack이 이미 실행 중입니다."
fi

# 5. 환경 정보 출력
print_status "현재 환경 정보:"
echo "  - Ansible 버전: $(ansible --version | head -n1)"
echo "  - kubectl 버전: $(kubectl version --client --short 2>/dev/null || echo 'N/A')"
echo "  - kind 클러스터: $(kubectl config current-context 2>/dev/null || echo 'N/A')"
echo "  - LocalStack: http://localhost:4566"

echo ""
print_status "🎉 설정이 완료되었습니다!"
echo ""
echo "다음 명령어로 Next.js 앱을 배포할 수 있습니다:"
echo "  ansible-playbook playbooks/deploy-nextjs.yml"
echo ""
echo "또는 간단히:"
echo "  ./scripts/deploy.sh"
