package com.example.apigateway.filter;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

/**
 * LoggingFilter is a global filter for Spring Cloud Gateway that logs incoming requests and outgoing responses.
 * It helps in monitoring and debugging by providing request and response details in the logs.
 *
 * Dependencies:
 * - org.slf4j: For logging.
 * - Spring Cloud Gateway: For filter integration.
 */
@Component
public class LoggingFilter implements GlobalFilter, Ordered {
    private static final Logger logger = LoggerFactory.getLogger(LoggingFilter.class);

     /**
      * Logs the HTTP method and URI of incoming requests and outgoing responses.
      *
      * @param exchange the current server exchange
      * @param chain the gateway filter chain
      * @return Mono<Void> indicating filter completion
      */
    @Override
    public Mono<Void> filter(ServerWebExchange exchange, org.springframework.cloud.gateway.filter.GatewayFilterChain chain) {
        logger.info("Request: {} {}", exchange.getRequest().getMethod(), exchange.getRequest().getURI());
        return chain.filter(exchange).then(Mono.fromRunnable(() -> {
            logger.info("Response: {} {} - Status {}", exchange.getRequest().getMethod(), exchange.getRequest().getURI(), exchange.getResponse().getStatusCode());
        }));
    }

     /**
      * Specifies the order of this filter. Lower values have higher precedence.
      * @return filter order
      */
    @Override
    public int getOrder() {
        return 0;
    }
}
