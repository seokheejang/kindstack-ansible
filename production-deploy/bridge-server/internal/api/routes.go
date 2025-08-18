package api

import (
	"bridge-server/internal/handlers"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

func SetupRoutes(r *gin.Engine, db *gorm.DB) {
	// API v1 그룹
	v1 := r.Group("/api/v1")
	{
		// 배포 관련 엔드포인트
		deployments := v1.Group("/deployments")
		{
			deployments.POST("", handlers.CreateDeployment(db))
			deployments.GET("", handlers.GetDeployments(db))
			deployments.GET("/:id", handlers.GetDeployment(db))
			deployments.GET("/:id/steps", handlers.GetDeploymentSteps(db))
		}

		// 인프라 콜백 엔드포인트 (Ansible Runner에서 호출)
		infra := v1.Group("/infra")
		{
			infra.POST("/callback", handlers.InfraCallback(db))
		}

		// 상태 확인 엔드포인트
		v1.GET("/health", handlers.HealthCheck())
	}
}
