package handlers

import (
	"bridge-server/internal/models"
	"bridge-server/internal/services"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// CreateDeployment 새로운 배포 생성
func CreateDeployment(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req models.CreateDeploymentRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		deployment := models.Deployment{
			Name:        req.Name,
			DockerImage: req.DockerImage,
			EnvConfig:   req.EnvConfig,
			Domain:      req.Domain,
			Status:      "pending",
		}

		if err := db.Create(&deployment).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "배포 생성 실패"})
			return
		}

		// 배포 단계들 초기화
		steps := []models.DeploymentStep{
			{DeploymentID: deployment.ID, StepName: "route53", Status: "pending"},
			{DeploymentID: deployment.ID, StepName: "load_balancer", Status: "pending"},
			{DeploymentID: deployment.ID, StepName: "k8s_service", Status: "pending"},
			{DeploymentID: deployment.ID, StepName: "ingress", Status: "pending"},
			{DeploymentID: deployment.ID, StepName: "domain_mapping", Status: "pending"},
		}

		if err := db.Create(&steps).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "배포 단계 생성 실패"})
			return
		}

		// Ansible Runner 트리거 (비동기)
		go services.TriggerAnsibleRunner(deployment)

		c.JSON(http.StatusCreated, gin.H{
			"message":    "배포가 시작되었습니다",
			"deployment": deployment,
		})
	}
}

// GetDeployments 모든 배포 목록 조회
func GetDeployments(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var deployments []models.Deployment
		if err := db.Preload("Steps").Find(&deployments).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "배포 목록 조회 실패"})
			return
		}

		c.JSON(http.StatusOK, gin.H{"deployments": deployments})
	}
}

// GetDeployment 특정 배포 조회
func GetDeployment(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		id, err := strconv.ParseUint(c.Param("id"), 10, 32)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "잘못된 배포 ID"})
			return
		}

		var deployment models.Deployment
		if err := db.Preload("Steps").First(&deployment, uint(id)).Error; err != nil {
			if err == gorm.ErrRecordNotFound {
				c.JSON(http.StatusNotFound, gin.H{"error": "배포를 찾을 수 없습니다"})
				return
			}
			c.JSON(http.StatusInternalServerError, gin.H{"error": "배포 조회 실패"})
			return
		}

		c.JSON(http.StatusOK, gin.H{"deployment": deployment})
	}
}

// GetDeploymentSteps 특정 배포의 단계들 조회
func GetDeploymentSteps(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		id, err := strconv.ParseUint(c.Param("id"), 10, 32)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "잘못된 배포 ID"})
			return
		}

		var steps []models.DeploymentStep
		if err := db.Where("deployment_id = ?", uint(id)).Find(&steps).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "배포 단계 조회 실패"})
			return
		}

		c.JSON(http.StatusOK, gin.H{"steps": steps})
	}
}
