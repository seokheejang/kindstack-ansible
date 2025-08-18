package database


import (
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func InitDB() (*gorm.DB, error) {
	// SQLite 데이터베이스 연결 (개발용)
	db, err := gorm.Open(sqlite.Open("bridge.db"), &gorm.Config{})
	if err != nil {
		return nil, err
	}

	return db, nil
}
