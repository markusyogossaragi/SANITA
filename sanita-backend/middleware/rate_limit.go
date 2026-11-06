package middleware

import (
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"golang.org/x/time/rate"
)

type ipLimiter struct {
	limiter  *rate.Limiter
	lastSeen time.Time
}

var (
	mu       sync.Mutex
	limiters = make(map[string]*ipLimiter)
)

func init() {
	// Auto-clean stale rate limit entries every 5 minutes
	go func() {
		for {
			time.Sleep(5 * time.Minute)
			mu.Lock()
			now := time.Now()
			for ip, l := range limiters {
				if now.Sub(l.lastSeen) > 5*time.Minute {
					delete(limiters, ip)
				}
			}
			mu.Unlock()
		}
	}()
}

func getLimiter(ip string) *rate.Limiter {
	mu.Lock()
	defer mu.Unlock()

	if l, exists := limiters[ip]; exists {
		l.lastSeen = time.Now()
		return l.limiter
	}

	// 60 requests per minute with burst of 30
	l := &ipLimiter{
		limiter:  rate.NewLimiter(rate.Every(time.Second), 30),
		lastSeen: time.Now(),
	}
	limiters[ip] = l
	return l.limiter
}

// RateLimit provides general API protection
func RateLimit() gin.HandlerFunc {
	return func(c *gin.Context) {
		ip := c.ClientIP()
		limiter := getLimiter(ip)

		if !limiter.Allow() {
			c.AbortWithStatusJSON(http.StatusTooManyRequests, gin.H{
				"status":  429,
				"message": "Terlalu banyak permintaan. Anti-DDoS perlindungan aktif, harap tunggu sebentar.",
			})
			return
		}

		c.Next()
	}
}

// StrictRateLimit protects login, register, and reporting against brute-force & spam
func StrictRateLimit() gin.HandlerFunc {
	strictLimiters := make(map[string]*ipLimiter)
	var muStrict sync.Mutex

	return func(c *gin.Context) {
		ip := c.ClientIP()

		muStrict.Lock()
		if _, exists := strictLimiters[ip]; !exists {
			// 5 requests per 10 seconds
			strictLimiters[ip] = &ipLimiter{
				limiter:  rate.NewLimiter(rate.Every(2*time.Second), 5),
				lastSeen: time.Now(),
			}
		}
		l := strictLimiters[ip]
		l.lastSeen = time.Now()
		lim := l.limiter
		muStrict.Unlock()

		if !lim.Allow() {
			c.AbortWithStatusJSON(http.StatusTooManyRequests, gin.H{
				"status":  429,
				"message": "Percobaan terlalu sering. Anti-Brute Force aktif, silakan coba lagi beberapa detik lagi.",
			})
			return
		}

		c.Next()
	}
}