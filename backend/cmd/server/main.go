package main

import (
	"fmt"
	"log"
	"os"

	"github.com/gofiber/contrib/fiberprometheus"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/gofiber/fiber/v2/middleware/recover"
	"github.com/gofiber/swagger"
	"github.com/joho/godotenv"

	_ "github.com/yourusername/skoservice-authenserver/backend/docs"
)

// @title SAuthenServer API
// @version 2.0
// @description Centralized Authentication and Authorization Service
// @termsOfService http://swagger.io/terms/

// @contact.name API Support
// @contact.email support@skoservice.com

// @license.name MIT
// @license.url https://opensource.org/licenses/MIT

// @host localhost:8080
// @BasePath /api/v1

// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization
// @description Type "Bearer" followed by a space and the access token.

func main() {
	// Load environment variables
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using system environment variables")
	}

	// Initialize Fiber app
	app := fiber.New(fiber.Config{
		AppName:      "SAuthenServer v2.0",
		ServerHeader: "Fiber",
		ErrorHandler: customErrorHandler,
	})

	// Middleware
	app.Use(recover.New())
	app.Use(logger.New(logger.Config{
		Format: "[${time}] ${status} - ${latency} ${method} ${path}\n",
	}))
	app.Use(cors.New(cors.Config{
		AllowOrigins:     getEnv("CORS_ORIGINS", "http://localhost:3000"),
		AllowHeaders:     "Origin, Content-Type, Accept, Authorization",
		AllowMethods:     "GET, POST, PUT, DELETE, OPTIONS",
		AllowCredentials: true,
	}))

	// Prometheus metrics middleware
	prometheus := fiberprometheus.New("sauthenserver")
	prometheus.RegisterAt(app, "/metrics")
	app.Use(prometheus.Middleware)

	// Swagger documentation
	app.Get("/swagger/*", swagger.HandlerDefault)

	// Health check
	app.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "ok",
			"service": "SAuthenServer",
			"version": "2.0.0",
		})
	})

	// API routes
	api := app.Group("/api")
	v1 := api.Group("/v1")

	// Route groups (to be implemented)
	setupAuthRoutes(v1)
	setupUserRoutes(v1)
	setupRoleRoutes(v1)

	// Start server
	port := getEnv("PORT", "8080")
	log.Printf("🚀 Server starting on port %s", port)
	log.Printf("📚 Swagger docs available at http://localhost:%s/swagger/index.html", port)

	if err := app.Listen(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}

func setupAuthRoutes(router fiber.Router) {
	auth := router.Group("/auth")
	auth.Post("/register", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{"message": "Register endpoint - To be implemented"})
	})
	auth.Post("/login", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{"message": "Login endpoint - To be implemented"})
	})
	auth.Post("/logout", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{"message": "Logout endpoint - To be implemented"})
	})
	auth.Get("/oauth/:provider", func(c *fiber.Ctx) error {
		provider := c.Params("provider")
		return c.JSON(fiber.Map{"message": fmt.Sprintf("OAuth %s - To be implemented", provider)})
	})
}

func setupUserRoutes(router fiber.Router) {
	users := router.Group("/users")
	users.Get("/", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{"message": "List users - To be implemented"})
	})
	users.Get("/:id", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{"message": "Get user - To be implemented"})
	})
	users.Put("/:id", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{"message": "Update user - To be implemented"})
	})
}

func setupRoleRoutes(router fiber.Router) {
	roles := router.Group("/roles")
	roles.Get("/", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{"message": "List roles - To be implemented"})
	})
}

func customErrorHandler(c *fiber.Ctx, err error) error {
	code := fiber.StatusInternalServerError
	if e, ok := err.(*fiber.Error); ok {
		code = e.Code
	}

	return c.Status(code).JSON(fiber.Map{
		"error": err.Error(),
		"code":  code,
	})
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
