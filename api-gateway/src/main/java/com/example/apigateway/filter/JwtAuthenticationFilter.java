package com.example.apigateway.filter;

import org.springframework.cloud.gateway.filter.GatewayFilter;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

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
    private static final String AUTHORIZATION_HEADER = "Authorization";
    private static final String BEARER_PREFIX = "Bearer ";
    private static final String SECRET_KEY = "replace_with_a_very_secret_key_which_is_long_enough";

     /**
      * Filters incoming requests to check for a valid JWT in the Authorization header.
      * If valid, allows the request to proceed; otherwise, responds with 401 Unauthorized.
      *
      * @param exchange the current server exchange
      * @param chain the gateway filter chain
      * @return Mono<Void> indicating filter completion
      */
    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        List<String> authHeaders = exchange.getRequest().getHeaders().get(AUTHORIZATION_HEADER);
        if (authHeaders == null || authHeaders.isEmpty() || !authHeaders.get(0).startsWith(BEARER_PREFIX)) {
            exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
            return exchange.getResponse().setComplete();
        }
        String token = authHeaders.get(0).substring(BEARER_PREFIX.length());
        try {
        Claims claims = Jwts.parser()
            .setSigningKey(SECRET_KEY.getBytes(StandardCharsets.UTF_8))
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
