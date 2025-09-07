# API Gateway for Microservices

This service acts as the single entry point for all client requests in the microservices architecture. It provides routing, authentication, rate limiting, and logging, and integrates with Eureka for service discovery and Redis for distributed rate limiting.

## Features
- **Dynamic Routing:** Auto-routes requests to microservices registered in Eureka.
- **Authentication:** JWT-based authentication filter.
- **Rate Limiting:** Redis-backed Bucket4J rate limiting filter.
- **Logging:** Request/response logging filter for observability.


## Libraries Used

- **Spring Cloud Gateway**: Provides a simple, effective way to route to APIs and provides an array of cross-cutting concerns such as security, monitoring/metrics, and resiliency. It is built on Spring WebFlux, making it highly scalable and reactive.
- **Spring Cloud Netflix Eureka Client**: Enables the gateway to register itself with the Eureka discovery server and to discover other services dynamically, allowing for dynamic routing and load balancing.
- **Spring Boot WebFlux**: A reactive, non-blocking web framework that supports high concurrency and is the foundation for Spring Cloud Gateway.
- **Spring Data Redis Reactive**: Integrates Redis as a distributed in-memory data store for rate limiting and caching, using reactive programming paradigms for scalability.
- **Bucket4J**: Implements the token bucket algorithm for rate limiting. It can be used in-memory or with Redis for distributed rate limiting across multiple gateway instances.
- **JJWT (io.jsonwebtoken)**: A Java library for creating and verifying JSON Web Tokens (JWTs). Used for parsing, validating, and extracting claims from JWTs in the authentication filter.

## How to Run
1. Make sure you have Java 22, Maven, and Redis installed and running.
2. From the `api-gateway` directory, run:
   ```bash
   mvn spring-boot:run
   ```
3. The gateway will be available at http://localhost:8080

## Configuration
- Port: 8080
- Service name: api-gateway
- Eureka server: http://localhost:8761/eureka/
- Redis: localhost:6379

## Alternatives
- **Kong**: Open-source API gateway built on NGINX.
- **NGINX**: Can be configured as a reverse proxy and API gateway.
- **Traefik**: Modern HTTP reverse proxy and load balancer.
- **Zuul**: Netflix's original gateway, now replaced by Spring Cloud Gateway in the Spring ecosystem.
