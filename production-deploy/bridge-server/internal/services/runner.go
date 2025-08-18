package services

import (
	"bridge-server/internal/models"
	"fmt"
	"log"
	"os"
	"os/exec"
)

// TriggerAnsibleRunner Ansible Runner 컨테이너를 트리거
func TriggerAnsibleRunner(deployment models.Deployment) {
	log.Printf("배포 ID %d에 대한 Ansible Runner 시작", deployment.ID)

	// 호스트의 홈 디렉토리 (환경 변수 또는 기본값 사용)
	homeDir := os.Getenv("HOST_HOME_DIR")
	if homeDir == "" {
		homeDir = "/Users/seokheejang" // 기본값 (호스트 홈)
	}

	// Docker 컨테이너 실행 명령어 구성
	dockerCmd := []string{
		"run", "--rm",
		"--name", fmt.Sprintf("ansible-runner-%d", deployment.ID),
		"-e", fmt.Sprintf("DEPLOYMENT_ID=%d", deployment.ID),
		"-e", fmt.Sprintf("DOCKER_IMAGE=%s", deployment.DockerImage),
		"-e", fmt.Sprintf("DOMAIN=%s", deployment.Domain),
		"-e", fmt.Sprintf("BRIDGE_SERVER_URL=http://host.docker.internal:8080"),
		"-e", fmt.Sprintf("ENV_CONFIG=%s", deployment.EnvConfig),
		"-v", "/Users/seokheejang/dev/seokheejang/kindstack-ansible/production-deploy:/ansible",
		"-v", fmt.Sprintf("%s/.kube:/root/.kube:ro", homeDir), // Kubernetes 설정 접근
		"-w", "/ansible",
		"ansible-runner:latest",
		"ansible-playbook", "playbooks/deploy-production.yml", "-v",
	}

	cmd := exec.Command("docker", dockerCmd...)
	
	// 명령어 실행
	output, err := cmd.CombinedOutput()
	if err != nil {
		log.Printf("Ansible Runner 실행 실패 (배포 ID: %d): %v\n출력: %s", deployment.ID, err, string(output))
		return
	}

	log.Printf("Ansible Runner 완료 (배포 ID: %d)", deployment.ID)
}
