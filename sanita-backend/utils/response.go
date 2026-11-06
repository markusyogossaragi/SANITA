package utils

import (
	"github.com/gin-gonic/gin"
)

type APIResponse struct {
	Status  int         `json:"status"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

func Success(c *gin.Context, statusCode int, message string, data interface{}) {
	c.JSON(statusCode, APIResponse{
		Status:  statusCode,
		Message: message,
		Data:    data,
	})
}

func Error(c *gin.Context, statusCode int, message string) {
	c.JSON(statusCode, APIResponse{
		Status:  statusCode,
		Message: message,
	})
}

func ValidationError(c *gin.Context, message string, data interface{}) {
	c.JSON(422, APIResponse{
		Status:  422,
		Message: message,
		Data:    data,
	})
}