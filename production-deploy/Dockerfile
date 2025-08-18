# Ansible Runner 컨테이너
FROM python:3.11-slim

# 시스템 패키지 설치
RUN apt-get update && apt-get install -y \
    curl \
    git \
    openssh-client \
    sshpass \
    && rm -rf /var/lib/apt/lists/*

# Ansible 및 필요한 패키지 설치
RUN pip install --no-cache-dir \
    ansible>=8.0.0 \
    boto3>=1.26.0 \
    botocore>=1.29.0 \
    kubernetes>=24.2.0 \
    PyYAML>=6.0 \
    requests>=2.28.0

# kubectl 설치
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && rm kubectl

# 작업 디렉토리 설정
WORKDIR /ansible

# Ansible 컬렉션 설치를 위한 requirements 복사
COPY requirements.yml .
RUN ansible-galaxy collection install -r requirements.yml

# 기본 환경 변수 설정
ENV ANSIBLE_HOST_KEY_CHECKING=False
ENV ANSIBLE_FORCE_COLOR=1
ENV ANSIBLE_CALLBACKS_ENABLED=bridge_callback

# 진입점 설정
CMD ["ansible-playbook", "--version"]
