# Microservices API Gateway Project

A comprehensive microservices architecture with API Gateway, service discovery, authentication, monitoring, and observability.

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Load Balancer │────│   API Gateway    │────│ Discovery Server│
│   (External)    │    │   (Port 8080)    │    │   (Port 8761)   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                                │
                    ┌───────────┼────────────┐
                    │           │            │
            ┌───────▼────┐ ┌────▼───────┐ ┌──▼────────────┐
            │Auth Service│ │User Service│ │Product Service│
            │(Dynamic)   │ │(Dynamic)   │ │(Dynamic)      │
            └────────────┘ └────────────┘ └───────────────┘
                                │
                                │
                    ┌───────────▼───────────┐
                    │   Monitoring Stack    │
                    │ Prometheus | Grafana  │
                    │  Zipkin   |   ELK     │
                    └───────────────────────┘
```

## 🚀 Services

### Core Services

1. **Discovery Server** (Port 8761 - Fixed)
   - Eureka server for service registration and discovery
   - Service health monitoring
   - Load balancing coordination

2. **API Gateway** (Port 8080 - Fixed)
   - Single entry point for all client requests
   - JWT authentication validation
   - Rate limiting and throttling
   - Request routing and load balancing
   - CORS handling

3. **Auth Service** (Dynamic Port - Discovered via Eureka)
   - JWT token generation and validation
   - User authentication
   - Security endpoints
   - Accessed via Gateway: `http://localhost:8080/auth-service`

4. **User Service** (Dynamic Port - Discovered via Eureka)
   - User management CRUD operations
   - User profile management
   - Secured with JWT
   - Accessed via Gateway: `http://localhost:8080/user-service`

5. **Product Service** (Dynamic Port - Discovered via Eureka)
   - Product catalog management
   - Product CRUD operations
   - Category management
   - Accessed via Gateway: `http://localhost:8080/product-service`

### Monitoring Stack

- **Prometheus** (Port 9090) - Metrics collection
- **Grafana** (Port 3000) - Visualization dashboards
- **Zipkin** (Port 9411) - Distributed tracing
- **ELK Stack** - Centralized logging
  - Elasticsearch (Port 9200)
  - Logstash (Port 5044)
  - Kibana (Port 5601)

## 🛠️ Technology Stack

- **Framework**: Spring Boot 3.2.5
- **Language**: Java 22
- **Cloud**: Spring Cloud 2023.0.1
- **Security**: JWT with JJWT 0.9.1
- **Database**: H2 (Development)
- **Monitoring**: Micrometer + Prometheus
- **Tracing**: Zipkin with Brave
- **API Gateway**: Spring Cloud Gateway
- **Discovery**: Netflix Eureka
- **Build Tool**: Maven
- **Containerization**: Docker & Docker Compose

## 📋 Prerequisites

- Java 22 or higher
- Maven 3.6 or higher
- Docker and Docker Compose (for monitoring)
- curl (for testing)

## 🚀 Quick Start

### 1. Start Monitoring Stack (Optional but recommended)

```bash
# Start monitoring infrastructure
./start-monitoring.sh

# Wait for services to be ready (2-3 minutes)
# Check status at http://localhost:3000 (Grafana)
```

### 2. Start Microservices

```bash
# Start all microservices in correct order
./start-services.sh

# This will:
# 1. Start Discovery Server (8761)
# 2. Start API Gateway (8080)
# 3. Start Auth Service (8081)
# 4. Start User Service (8082)
# 5. Start Product Service (8083)
```

### 3. Test the APIs

```bash
# Run comprehensive API tests
./test-apis.sh

# This will test:
# - Service health checks
# - Authentication flow
# - User CRUD operations
# - Product CRUD operations
# - Rate limiting
# - Monitoring endpoints
```

### 4. Stop Services

```bash
# Stop all microservices
./stop-services.sh

# Stop monitoring stack
docker-compose -f docker-compose-monitoring.yml down
```

## 🔧 Manual Setup

### Start Services Individually

```bash
# 1. Discovery Server (must be first)
cd discovery-server && mvn spring-boot:run &

# 2. API Gateway (wait for discovery server)
cd api-gateway && mvn spring-boot:run &

# 3. Auth Service
cd auth-service && mvn spring-boot:run &

# 4. User Service
cd user-service && mvn spring-boot:run &

# 5. Product Service
cd product-service && mvn spring-boot:run &
```

## 🧪 API Testing

### Authentication

```bash
# Login to get JWT token
curl -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"password"}'

# Response: {"token":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."}
```

### User Operations

```bash
# Create user (requires JWT token)
curl -X POST http://localhost:8080/users \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"username":"john","email":"john@example.com","firstName":"John","lastName":"Doe"}'

# Get all users
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  http://localhost:8080/users

# Get user by ID
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  http://localhost:8080/users/1
```

### Product Operations

```bash
# Create product (requires JWT token)
curl -X POST http://localhost:8080/products \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Laptop","description":"Gaming laptop","price":999.99,"category":"Electronics"}'

# Get all products
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  http://localhost:8080/products

# Get product by ID
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  http://localhost:8080/products/1
```

## 📊 Monitoring & Observability

### Service URLs

- **Discovery Server**: http://localhost:8761
- **API Gateway**: http://localhost:8080
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/admin)
- **Zipkin**: http://localhost:9411
- **Kibana**: http://localhost:5601

### Metrics Endpoints

```bash
# Gateway metrics
curl http://localhost:8080/actuator/metrics
curl http://localhost:8080/actuator/prometheus

# Service metrics
curl http://localhost:8082/actuator/health
curl http://localhost:8083/actuator/health
```

### Grafana Dashboards

1. **JVM Metrics** - Memory, CPU, GC
2. **Spring Boot Metrics** - HTTP requests, database connections
3. **Gateway Metrics** - Route-specific metrics
4. **Business Metrics** - User/Product operations

## 🔒 Security

### JWT Authentication

- All API endpoints (except auth) require JWT tokens
- Tokens include user information and expiration
- Gateway validates tokens before forwarding requests

### Rate Limiting

- Configured per-user rate limiting
- Default: 10 requests per minute per user
- Returns 429 Too Many Requests when exceeded

### CORS

- Configured for cross-origin requests
- Allows common HTTP methods
- Configurable origins

## 🏗️ Project Structure

```
MicroservicesApiGateway/
├── discovery-server/          # Eureka service registry
├── api-gateway/               # Spring Cloud Gateway
├── auth-service/              # JWT authentication
├── user-service/              # User management
├── product-service/           # Product management
├── monitoring/                # Monitoring configuration
│   ├── prometheus.yml
│   └── grafana/
├── docker-compose-monitoring.yml
├── start-services.sh          # Start all services
├── stop-services.sh           # Stop all services
├── service-manager.sh         # Individual service management
├── test-apis.sh               # API functionality testing
├── test-load-balancing.sh     # Load balancing tests
├── setup-load-test.sh         # Load test environment setup
├── cleanup-load-test.sh       # Load test cleanup
├── start-monitoring.sh        # Start monitoring stack
├── test-apis.sh               # API testing script
├── MONITORING.md              # Monitoring documentation
└── README.md                  # This file
```

## 🔧 Configuration

### Environment Variables

```bash
# Service ports
DISCOVERY_PORT=8761
GATEWAY_PORT=8080
AUTH_PORT=8081
USER_PORT=8082
PRODUCT_PORT=8083

# JWT Configuration
JWT_SECRET=your-secret-key
JWT_EXPIRATION=86400000

# Database
DB_URL=jdbc:h2:mem:testdb
DB_USERNAME=sa
DB_PASSWORD=
```

### Application Profiles

- `development` - H2 database, debug logging
- `production` - External database, optimized logging
- `docker` - Container-specific configuration

## 🐛 Troubleshooting

### Common Issues

1. **Port Already in Use**
   ```bash
   # Find process using port
   lsof -i :8080
   
   # Kill process
   kill -9 <PID>
   ```

2. **Services Not Registering**
   - Ensure Discovery Server is running first
   - Check application.yml for correct Eureka URL
   - Verify network connectivity

3. **Authentication Issues**
   - Check JWT token format
   - Verify token hasn't expired
   - Ensure correct Authorization header format

4. **Monitoring Not Working**
   - Start monitoring stack first
   - Check Docker containers are running
   - Verify port accessibility

### Logs

```bash
# Service logs (when using start-services.sh)
tail -f logs/discovery-server.log
tail -f logs/api-gateway.log
tail -f logs/auth-service.log
tail -f logs/user-service.log
tail -f logs/product-service.log

# Direct Maven logs
cd service-directory && mvn spring-boot:run
```

## 📈 Performance Considerations

### Load Balancing

- Gateway uses Spring Cloud LoadBalancer
- Round-robin distribution by default
- Health check-based routing
- Support for multiple service instances

#### Load Balancing Testing
```bash
# Setup load test environment
./setup-load-test.sh

# Run comprehensive load balancing tests
./test-load-balancing.sh

# Clean up after testing
./cleanup-load-test.sh
```

See [LOAD_BALANCING_TESTS.md](LOAD_BALANCING_TESTS.md) for detailed testing guide.

### Caching

- Service discovery information cached
- JWT tokens validated with caching
- Database queries optimized

### Scaling

- Services are stateless (except auth tokens)
- Can run multiple instances behind load balancer
- Database should be externalized for production
- Dynamic port allocation prevents port conflicts

## 🔄 Development Workflow

1. **Make Changes**: Edit service code
2. **Build**: `mvn clean compile` in service directory
3. **Test**: Run individual service or full test suite
4. **Monitor**: Check Grafana dashboards for metrics
5. **Deploy**: Restart specific service or full stack

## 🚀 Production Deployment

### Docker Deployment

```bash
# Build all services
for service in discovery-server api-gateway auth-service user-service product-service; do
  cd $service
  mvn clean package
  cd ..
done

# Create Docker images (Dockerfiles needed)
# Deploy with Docker Compose or Kubernetes
```

### Kubernetes Deployment

```bash
# Example Kubernetes resources needed:
# - ConfigMaps for application.yml
# - Secrets for JWT keys
# - Services for inter-service communication
# - Ingress for external access
# - HorizontalPodAutoscaler for scaling
```

## 📝 Additional Documentation

- [Monitoring Setup](MONITORING.md) - Detailed monitoring configuration
- [Service READMEs](*/README.md) - Individual service documentation
- [API Documentation](API.md) - Detailed API specifications (create as needed)

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Make changes with tests
4. Update documentation
5. Submit pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
