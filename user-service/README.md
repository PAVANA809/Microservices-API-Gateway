# User Service

## Overview
The User Service is a microservice that provides comprehensive user management functionality with CRUD operations. It's part of the larger microservices API gateway architecture and integrates with Eureka for service discovery and JWT for authentication.

## Features
- **User Management**: Full CRUD operations for user entities
- **Search & Filtering**: Search users by name, filter by active status
- **Pagination**: Support for paginated user listings with sorting
- **Validation**: Input validation with detailed error responses
- **JWT Security**: Secure endpoints with JWT token validation
- **Service Discovery**: Automatic registration with Eureka server
- **Health Checks**: Built-in health monitoring endpoints

## Technology Stack
- **Spring Boot 3.2.5**: Core application framework
- **Spring Data JPA**: Database operations and repository pattern
- **Spring Security**: JWT-based authentication and authorization
- **Spring Cloud Netflix Eureka**: Service discovery and registration
- **H2 Database**: In-memory database for development
- **Bean Validation**: Input validation with annotations
- **Maven**: Build and dependency management

## Architecture

### Package Structure
```
com.example.userservice/
├── UserServiceApplication.java     # Main application class
├── config/                        # Configuration classes
│   ├── JwtUtil.java              # JWT utility for token operations
│   └── SecurityConfig.java       # Spring Security configuration
├── controller/                    # REST controllers
│   └── UserController.java       # User management endpoints
├── dto/                          # Data Transfer Objects
│   ├── CreateUserDto.java        # DTO for user creation
│   └── UpdateUserDto.java        # DTO for user updates
├── exception/                     # Exception handling
│   ├── DuplicateUserException.java
│   ├── GlobalExceptionHandler.java
│   └── UserNotFoundException.java
├── filter/                        # Security filters
│   └── JwtAuthenticationFilter.java
├── model/                         # Entity classes
│   └── User.java                 # User entity
├── repository/                    # Data access layer
│   └── UserRepository.java       # User repository
└── service/                       # Business logic
    └── UserService.java          # User service implementation
```

## Database Schema

### User Entity
```sql
CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(15),
    address TEXT,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);
```

## API Endpoints

### User Management

#### Create User
```http
POST /api/users
Content-Type: application/json
Authorization: Bearer <jwt-token>

{
  "username": "johndoe",
  "email": "john.doe@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "phone": "+1234567890",
  "address": "123 Main St, City, State"
}
```

#### Get User by ID
```http
GET /api/users/{id}
Authorization: Bearer <jwt-token>
```

#### Get User by Username
```http
GET /api/users/username/{username}
Authorization: Bearer <jwt-token>
```

#### Get All Users (Paginated)
```http
GET /api/users?page=0&size=10&sort=username&sortDirection=asc
Authorization: Bearer <jwt-token>
```

#### Get Active Users
```http
GET /api/users/active
Authorization: Bearer <jwt-token>
```

#### Search Users by Name
```http
GET /api/users/search?name=john
Authorization: Bearer <jwt-token>
```

#### Update User
```http
PUT /api/users/{id}
Content-Type: application/json
Authorization: Bearer <jwt-token>

{
  "firstName": "John Updated",
  "lastName": "Doe Updated",
  "phone": "+1987654321",
  "active": true
}
```

#### Delete User
```http
DELETE /api/users/{id}
Authorization: Bearer <jwt-token>
```

#### Deactivate User
```http
PUT /api/users/{id}/deactivate
Authorization: Bearer <jwt-token>
```

#### Activate User
```http
PUT /api/users/{id}/activate
Authorization: Bearer <jwt-token>
```

### Utility Endpoints

#### Health Check
```http
GET /api/users/health
```

#### User Statistics
```http
GET /api/users/stats
Authorization: Bearer <jwt-token>
```

#### Check User Exists
```http
HEAD /api/users/{id}
Authorization: Bearer <jwt-token>
```

## Configuration

### application.yml
```yaml
server:
  port: 8082

spring:
  application:
    name: user-service
  datasource:
    url: jdbc:h2:mem:userdb
    driverClassName: org.h2.Driver
    username: sa
    password:
  jpa:
    database-platform: org.hibernate.dialect.H2Dialect
    hibernate:
      ddl-auto: create-drop
    show-sql: true
  h2:
    console:
      enabled: true

eureka:
  client:
    serviceUrl:
      defaultZone: http://localhost:8761/eureka/
  instance:
    preferIpAddress: true

jwt:
  secret: mySecretKey
```

## Security

### JWT Authentication
- All endpoints except `/api/users/health` require JWT authentication
- JWT tokens are validated using the shared secret key
- Invalid or expired tokens result in 401 Unauthorized responses

### Endpoint Security
- **Public**: Health check endpoint
- **Protected**: All user management endpoints
- **H2 Console**: Enabled for development (should be disabled in production)

## Error Handling

### Standard Error Responses
```json
{
  "errorCode": "USER_NOT_FOUND",
  "message": "User not found with ID: 123",
  "timestamp": "2024-01-15T10:30:00"
}
```

### Validation Error Response
```json
{
  "errorCode": "VALIDATION_ERROR",
  "message": "Input validation failed",
  "fieldErrors": {
    "username": "Username must be between 3 and 50 characters",
    "email": "Email should be valid"
  },
  "timestamp": "2024-01-15T10:30:00"
}
```

## Building and Running

### Prerequisites
- Java 22 or higher
- Maven 3.6+
- Discovery Server running on port 8761

### Build the Service
```bash
cd user-service
mvn clean compile
```

### Run the Service
```bash
mvn spring-boot:run
```

### Build JAR
```bash
mvn clean package
java -jar target/user-service-0.0.1-SNAPSHOT.jar
```

## Service Registration
The service automatically registers with Eureka Discovery Server at startup:
- **Service Name**: user-service
- **Port**: 8082
- **Health Check**: /api/users/health

## Development Features

### H2 Database Console
Access the H2 console for development:
- **URL**: http://localhost:8082/h2-console
- **JDBC URL**: jdbc:h2:mem:userdb
- **Username**: sa
- **Password**: (empty)

### Sample Data
The service starts with an empty database. You can create test users using the API endpoints.

## Integration with Other Services

### API Gateway
- Routes requests to user-service through the API gateway
- Applies rate limiting and authentication filters

### Authentication Service
- Validates JWT tokens issued by the auth-service
- Shares the same JWT secret for token verification

## Monitoring and Logging
- Built-in health check endpoint for monitoring
- Spring Boot Actuator can be added for additional metrics
- Request/response logging through security filters

## Production Considerations
1. Replace H2 with production database (PostgreSQL, MySQL)
2. Disable H2 console
3. Configure proper logging levels
4. Add monitoring and metrics collection
5. Implement proper secret management
6. Configure SSL/TLS for secure communication

## Testing
You can test the service using curl or any REST client:

```bash
# Health check (no auth required)
curl http://localhost:8082/api/users/health

# Create user (requires JWT token)
curl -X POST http://localhost:8082/api/users \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <your-jwt-token>" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "firstName": "Test",
    "lastName": "User"
  }'
```
