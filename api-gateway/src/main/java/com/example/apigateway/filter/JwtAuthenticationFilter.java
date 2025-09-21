package com.example.apigateway.filter;

import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
// import io.jsonwebtoken.security.Keys;

import java.nio.charset.StandardCharsets;
import java.util.List;

/**
 * JwtAuthenticationFilter is a global filter for Spring Cloud Gateway that verifies JWT tokens in incoming requests.
 * It checks the Authorization header, validates the JWT using a secret key, and rejects unauthorized requests.
 * If the token is valid, claims are attached to the request for downstream services.
 *
 * Dependencies:
 * - io.jsonwebtoken (JJWT): For parsing and validating JWT tokens.
 * - Spring Cloud Gateway: For filter integration.
 */
@Component
public class JwtAuthenticationFilter implements GlobalFilter, Ordered {
    private static final Logger logger = LoggerFactory.getLogger(JwtAuthenticationFilter.class);
    private static final String AUTHORIZATION_HEADER = "Authorization";
    private static final String BEARER_PREFIX = "Bearer ";
    private static final String SECRET_KEY = "ncdsmncsmdncsldncsdlncsldcnsdlncsdlcnsdlcnsdlsdcsmdncsdcndlcsdcsdcsdncsd";

    /**
     * Checks if the given path is a public endpoint that doesn't require authentication.
     * @param path the request path
     * @return true if the path is public, false otherwise
     */
    private boolean isPublicEndpoint(String path) {
        // List of public endpoints that don't require authentication
        String[] publicPaths = {
            "/auth-service/api/auth/login",
            "/auth-service/api/auth/signup",
            "/auth-service/api/auth/health",
            "/auth-service/actuator/health",
            "/user-service/actuator/health",
            "/product-service/actuator/health",
            "/actuator/health",
            "/actuator/info",
            "/actuator/metrics",
            "/actuator/prometheus",
            "/product-service/api/products"  // Allow public access to product listings
        };
        
        logger.info("JWT Filter: Checking if path '{}' is public", path);
        
        for (String publicPath : publicPaths) {
            if (path.equals(publicPath) || path.startsWith(publicPath + "/")) {
                logger.info("JWT Filter: Path '{}' matches public path '{}'", path, publicPath);
                return true;
            }
        }
        
        logger.info("JWT Filter: Path '{}' is not public", path);
        return false;
    }

     /**
      * Filters incoming requests to check for a valid JWT in the Authorization header.
      * If valid, allows the request to proceed; otherwise, responds with 401 Unauthorized.
      * Allows certain public endpoints to pass through without authentication.
      *
      * @param exchange the current server exchange
      * @param chain the gateway filter chain
      * @return Mono<Void> indicating filter completion
      */
    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        String path = exchange.getRequest().getURI().getPath();
        
        // Debug logging
        logger.info("JWT Filter: Processing request to path: {}", path);
        
        // Allow public endpoints to pass through without authentication
        if (isPublicEndpoint(path)) {
            logger.info("JWT Filter: Public endpoint detected, allowing through: {}", path);
            return chain.filter(exchange);
        }
        
        logger.info("JWT Filter: Private endpoint, checking for JWT token: {}", path);
        
        List<String> authHeaders = exchange.getRequest().getHeaders().get(AUTHORIZATION_HEADER);
        if (authHeaders == null || authHeaders.isEmpty() || !authHeaders.get(0).startsWith(BEARER_PREFIX)) {
            logger.warn("JWT Filter: No valid Authorization header found, returning 401");
            exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
            return exchange.getResponse().setComplete();
        }
        String token = authHeaders.get(0).substring(BEARER_PREFIX.length());
        try {
            Claims claims = Jwts.parserBuilder()
                .setSigningKey(SECRET_KEY.getBytes(StandardCharsets.UTF_8))
                .build()
                .parseClaimsJws(token)
                .getBody();
            // Optionally set claims in request attributes for downstream services
            exchange.getAttributes().put("jwtClaims", claims);
        } catch (Exception e) {
            exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
            return exchange.getResponse().setComplete();
        }
        return chain.filter(exchange);
    }

     /**
      * Specifies the order of this filter. Lower values have higher precedence.
      * @return filter order
      */
    @Override
    public int getOrder() {
        return -1; // Run before other filters
    }
}
