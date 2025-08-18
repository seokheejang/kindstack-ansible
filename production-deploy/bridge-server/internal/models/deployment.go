package models

import (
	"time"
)

// Deployment 배포 정보를 담는 모델
type Deployment struct {
	ID          uint             `json:"id" gorm:"primaryKey"`
	Name        string           `json:"name" gorm:"not null"`
	Status      string           `json:"status" gorm:"default:'pending'"` // pending, running, completed, failed
	DockerImage string           `json:"docker_image"`
	EnvConfig   string           `json:"env_config" gorm:"type:text"`
	Domain      string           `json:"domain"`
	CreatedAt   time.Time        `json:"created_at"`
	UpdatedAt   time.Time        `json:"updated_at"`
	Steps       []DeploymentStep `json:"steps" gorm:"foreignKey:DeploymentID"`
}

// DeploymentStep 배포 단계별 상태를 담는 모델
type DeploymentStep struct {
	ID           uint      `json:"id" gorm:"primaryKey"`
	DeploymentID uint      `json:"deployment_id"`
	StepName     string    `json:"step_name"` // route53, load_balancer, k8s_service, ingress, domain_mapping
	Status       string    `json:"status" gorm:"default:'pending'"` // pending, running, completed, failed
	Message      string    `json:"message" gorm:"type:text"`
	StartedAt    *time.Time `json:"started_at"`
	CompletedAt  *time.Time `json:"completed_at"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

// CreateDeploymentRequest 배포 생성 요청 구조체
type CreateDeploymentRequest struct {
	Name        string `json:"name" binding:"required"`
	DockerImage string `json:"docker_image" binding:"required"`
	EnvConfig   string `json:"env_config"`
	Domain      string `json:"domain" binding:"required"`
}

// CallbackRequest Ansible Runner에서 보내는 콜백 요청 구조체
type CallbackRequest struct {
	DeploymentID uint   `json:"deployment_id" binding:"required"`
	StepName     string `json:"step_name" binding:"required"`
	Status       string `json:"status" binding:"required"`
	Message      string `json:"message"`
}
