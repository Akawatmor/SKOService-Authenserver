package response
package response

import (
	"github.com/gofiber/fiber/v2"
)

type Response struct {
	Success bool        `json:"success"`
	Data    interface{} `json:"data,omitempty"`
	Error   *Error      `json:"error,omitempty"`
	Meta    *Meta       `json:"meta,omitempty"`
}

type Error struct {
	Code    string `json:"code"`











































































































}	})		},			Details: detail,			Message: message,			Code:    "INTERNAL_SERVER_ERROR",		Error: &Error{		Success: false,	return c.Status(fiber.StatusInternalServerError).JSON(Response{	}		detail = details[0]	if len(details) > 0 {	detail := ""func InternalServerError(c *fiber.Ctx, message string, details ...string) error {// InternalServerError sends a 500 Internal Server Error response}	})		},			Message: message,			Code:    "NOT_FOUND",		Error: &Error{		Success: false,	return c.Status(fiber.StatusNotFound).JSON(Response{func NotFound(c *fiber.Ctx, message string) error {// NotFound sends a 404 Not Found response}	})		},			Message: message,			Code:    "FORBIDDEN",		Error: &Error{		Success: false,	return c.Status(fiber.StatusForbidden).JSON(Response{func Forbidden(c *fiber.Ctx, message string) error {// Forbidden sends a 403 Forbidden response}	})		},			Message: message,			Code:    "UNAUTHORIZED",		Error: &Error{		Success: false,	return c.Status(fiber.StatusUnauthorized).JSON(Response{func Unauthorized(c *fiber.Ctx, message string) error {// Unauthorized sends a 401 Unauthorized response}	})		},			Details: detail,			Message: message,			Code:    "BAD_REQUEST",		Error: &Error{		Success: false,	return c.Status(fiber.StatusBadRequest).JSON(Response{	}		detail = details[0]	if len(details) > 0 {	detail := ""func BadRequest(c *fiber.Ctx, message string, details ...string) error {// BadRequest sends a 400 Bad Request response}	return c.SendStatus(fiber.StatusNoContent)func NoContent(c *fiber.Ctx) error {// NoContent sends a 204 No Content response}	})		Data:    data,		Success: true,	return c.Status(fiber.StatusCreated).JSON(Response{func Created(c *fiber.Ctx, data interface{}) error {// Created sends a 201 Created response}	})		Meta:    meta,		Data:    data,		Success: true,	return c.JSON(Response{func SuccessWithMeta(c *fiber.Ctx, data interface{}, meta *Meta) error {// SuccessWithMeta sends a successful response with pagination metadata}	})		Data:    data,		Success: true,	return c.JSON(Response{func Success(c *fiber.Ctx, data interface{}) error {// Success sends a successful response}	TotalPages int `json:"total_pages,omitempty"`	Total      int `json:"total,omitempty"`	PerPage    int `json:"per_page,omitempty"`	Page       int `json:"page,omitempty"`type Meta struct {}	Details string `json:"details,omitempty"`	Message string `json:"message"`