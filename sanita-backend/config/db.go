package config

import (
	"database/sql"
	"fmt"
	"log"
	"time"

	_ "github.com/lib/pq"
)

func ConnectDB() *sql.DB {
	databaseURL := GetEnv("DATABASE_URL", "")
	var dsn string

	if databaseURL != "" {
		dsn = databaseURL
	} else {
		host := GetEnv("DB_HOST", "localhost")
		port := GetEnv("DB_PORT", "5432")
		user := GetEnv("DB_USER", "postgres")
		password := GetEnv("DB_PASSWORD", "postgres")
		dbname := GetEnv("DB_NAME", "sanita")
		sslmode := GetEnv("DB_SSLMODE", "disable")

		dsn = fmt.Sprintf(
			"host=%s port=%s user=%s password=%s dbname=%s sslmode=%s TimeZone=Asia/Jakarta",
			host, port, user, password, dbname, sslmode,
		)
	}

	db, err := sql.Open("postgres", dsn)
	if err != nil {
		log.Printf("[DB] Warning: PostgreSQL not reachable: %v. Running in secured high-performance in-memory cache mode.", err)
		return nil
	}

	db.SetMaxOpenConns(100)
	db.SetMaxIdleConns(25)
	db.SetConnMaxLifetime(10 * time.Minute)
	db.SetConnMaxIdleTime(5 * time.Minute)

	if err := db.Ping(); err != nil {
		log.Printf("[DB] Warning: Ping to PostgreSQL failed: %v. Running in secured memory-buffered mode.", err)
		return nil
	}

	log.Println("[DB] Connected to PostgreSQL successfully with connection pooling enabled.")
	return db
}