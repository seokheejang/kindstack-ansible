package handlers

import (
	"bridge-server/internal/models"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// InfraCallback Ansible Runner에서 호출하는 콜백 핸들러
func InfraCallback(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req models.CallbackRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		// 해당 배포 단계 찾기
		var step models.DeploymentStep
		if err := db.Where("deployment_id = ? AND step_name = ?", req.DeploymentID, req.StepName).First(&step).Error; err != nil {
			if err == gorm.ErrRecordNotFound {
				c.JSON(http.StatusNotFound, gin.H{"error": "배포 단계를 찾을 수 없습니다"})
				return
			}
			c.JSON(http.StatusInternalServerError, gin.H{"error": "배포 단계 조회 실패"})
			return
		}

		// 상태 업데이트
		now := time.Now()
		step.Status = req.Status
		step.Message = req.Message

		if req.Status == "running" && step.StartedAt == nil {
			step.StartedAt = &now
		}

		if req.Status == "completed" || req.Status == "failed" {
			step.CompletedAt = &now
		}

		if err := db.Save(&step).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "배포 단계 업데이트 실패"})
			return
		}

		// 전체 배포 상태 업데이트
		var deployment models.Deployment
		if err := db.First(&deployment, req.DeploymentID).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "배포 정보 조회 실패"})
			return
		}

		// 모든 단계의 상태를 확인하여 전체 배포 상태 결정
		var steps []models.DeploymentStep
		if err := db.Where("deployment_id = ?", req.DeploymentID).Find(&steps).Error; err == nil {
			allCompleted := true
			anyFailed := false
			anyRunning := false

			for _, s := range steps {
				if s.Status == "failed" {
					anyFailed = true
					break
				}
				if s.Status == "running" {
					anyRunning = true
				}
				if s.Status != "completed" {
					allCompleted = false
				}
			}

			if anyFailed {
				deployment.Status = "failed"
			} else if anyRunning {
				deployment.Status = "running"
			} else if allCompleted {
				deployment.Status = "completed"
			}

			db.Save(&deployment)
		}

		c.JSON(http.StatusOK, gin.H{
			"message": "콜백이 성공적으로 처리되었습니다",
			"step":    step,
		})
	}
}

// HealthCheck 헬스체크 핸들러
func HealthCheck() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "healthy",
			"service": "bridge-server",
			"time":    time.Now(),
		})
	}
}
