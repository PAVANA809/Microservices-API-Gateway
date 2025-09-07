# Authentication Service for Microservices API Gateway

## Overview

The Authentication Service is a central component responsible for user authentication and JWT token management in the microservices architecture. It provides secure user registration, login functionality, and token validation services.

## Features
- **User Registration**: Secure signup with validation and password encryption
- **User Authentication**: Login with JWT token generation
- **Token Validation**: Endpoint to validate JWT tokens for other services
- **Password Security**: BCrypt encryption for secure password storage
- **Database Integration**: H2 in-memory database for development (easily replaceable with production databases)

## Architecture

### Components
- **Model**: User entity with JPA annotations
- **Repository**: Spring Data JPA repository for database operations
- **Service Layer**: Business logic for authentication operations
- **Controller**: REST endpoints for client interactions
- **Security Configuration**: Spring Security setup for endpoint protection

## API Endpoints

### Authentication Endpoints
- `POST /api/auth/signup` - Register a new user
- `POST /api/auth/login` - Authenticate user and get JWT token
- `GET /api/auth/validate` - Validate JWT token
- `GET /api/auth/health` - Health check endpoint

### Database Console (Development)
- `GET /h2-console` - H2 database console (development only)

## Libraries Used

- **Spring Boot Starter Web**: REST API development framework
- **Spring Boot Starter Data JPA**: Database operations and ORM
- **Spring Boot Starter Security**: Authentication and authorization
- **Spring Boot Starter Validation**: Input validation
- **Spring Cloud Netflix Eureka Client**: Service discovery integration
- **H2 Database**: In-memory database for development
- **JJWT**: JWT creation and validation library
- **BCrypt**: Password hashing algorithm

## Configuration

### Application Properties
- **Port**: 8081
- **Service Name**: auth-service
- **Database**: H2 in-memory database
- **JWT Secret**: Configurable secret key for token signing
- **JWT Expiration**: 24 hours (configurable)
- **Eureka Server**: http://localhost:8761/eureka/

## How to Run

1. Make sure you have Java 22 and Maven installed
2. Ensure the Discovery Server is running on port 8761
3. From the `auth-service` directory, run:
   ```bash
   mvn spring-boot:run
   ```
4. The service will be available at http://localhost:8081

## Testing the Service

### Register a User
```bash
curl -X POST http://localhost:8081/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "password123"
  }'
```

### Login
```bash
curl -X POST http://localhost:8081/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "password123"
  }'
```

**Note:** If you get a 403 Forbidden error, the Spring Security configuration may need to be updated. The security configuration currently permits all requests to `/api/auth/**` endpoints, but if you're still getting 403 errors, you can temporarily disable CSRF and authentication for testing by updating the SecurityConfig.

### Validate Token
```bash
curl -X GET http://localhost:8081/api/auth/validate \
  -H "Authorization: Bearer YOUR_JWT_TOKEN_HERE"
```

## Security Considerations

- Passwords are encrypted using BCrypt
- JWT tokens expire after 24 hours
- CORS is enabled for development (should be restricted in production)
- H2 console is enabled for development (should be disabled in production)
- Secret key should be externalized in production

## Integration with API Gateway

The Authentication Service integrates with the API Gateway's JWT filter to provide authentication across the microservices ecosystem. The gateway can validate tokens by calling the `/api/auth/validate` endpoint.

## Production Considerations

- Replace H2 with a production database (PostgreSQL, MySQL, etc.)
- Externalize JWT secret key
- Implement proper logging and monitoring
- Add rate limiting
- Disable H2 console
- Implement proper CORS policies
- Add comprehensive error handling and validation
