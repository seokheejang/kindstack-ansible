package main

import (
	"bridge-server/internal/api"
	"bridge-server/internal/database"
	"bridge-server/internal/models"
	"log"

	"github.com/gin-gonic/gin"
)

func main() {
	// 데이터베이스 초기화
	db, err := database.InitDB()
	if err != nil {
		log.Fatal("데이터베이스 연결 실패:", err)
	}

	// 마이그레이션 실행
	err = db.AutoMigrate(&models.Deployment{}, &models.DeploymentStep{})
	if err != nil {
		log.Fatal("마이그레이션 실패:", err)
	}

	// Gin 라우터 설정
	r := gin.Default()

	// CORS 미들웨어 추가 (간단한 버전)
	r.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization")
		
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}
		
		c.Next()
	})

	// API 라우트 설정
	api.SetupRoutes(r, db)

	log.Println("Bridge 서버가 :8080 포트에서 시작됩니다...")
	r.Run(":8080")
}
