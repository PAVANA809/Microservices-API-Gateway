# Monitoring & Logging Guide

## Overview
This guide explains how to set up comprehensive monitoring and logging for the microservices architecture using:
- **Micrometer** for metrics collection
- **Prometheus** for metrics storage
- **Grafana** for visualization
- **Zipkin** for distributed tracing
- **ELK Stack** (Elasticsearch, Logstash, Kibana) for centralized logging

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Microservices │────│   Prometheus    │────│     Grafana     │
│   (Micrometer)  │    │    (Metrics)    │    │ (Visualization) │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │
         │ (Traces)
         ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Zipkin      │    │   Logstash      │────│     Kibana      │
│   (Tracing)     │    │ (Log Processing)│    │  (Log Search)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │ Elasticsearch   │
                       │ (Log Storage)   │
                       └─────────────────┘
```

## Quick Start

### 1. Start Monitoring Stack
```bash
# Start all monitoring services
docker-compose -f docker-compose-monitoring.yml up -d

# Check status
docker-compose -f docker-compose-monitoring.yml ps
```

### 2. Start Your Microservices
```bash
# Start each service in separate terminals
cd discovery-server && mvn spring-boot:run
cd api-gateway && mvn spring-boot:run
cd auth-service && mvn spring-boot:run
cd user-service && mvn spring-boot:run
cd product-service && mvn spring-boot:run
```

### 3. Access Monitoring Tools
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/admin)
- **Zipkin**: http://localhost:9411
- **Kibana**: http://localhost:5601
- **Elasticsearch**: http://localhost:9200

## Metrics Collection (Micrometer + Prometheus)

### What's Monitored
Each microservice automatically exposes metrics at `/actuator/prometheus`:
- **JVM Metrics**: Memory, GC, threads
- **HTTP Metrics**: Request rates, response times, status codes
- **Database Metrics**: Connection pools, query times
- **Custom Metrics**: Business-specific metrics

### Available Endpoints
```bash
# Health check
curl http://localhost:8081/actuator/health

# Metrics in Prometheus format
curl http://localhost:8081/actuator/prometheus

# All available actuator endpoints
curl http://localhost:8081/actuator
```

### Key Metrics to Monitor
- `http_server_requests_seconds_count` - Request count
- `http_server_requests_seconds_sum` - Total response time
- `jvm_memory_used_bytes` - JVM memory usage
- `jvm_gc_pause_seconds` - Garbage collection times
- `hikaricp_connections_active` - Database connections

## Distributed Tracing (Zipkin)

### How it Works
- Each request gets a unique `traceId`
- Each service operation gets a `spanId`
- Traces automatically flow between services
- View complete request journeys in Zipkin UI

### Trace Information in Logs
Logs include trace correlation:
```
2024-01-15 10:30:00.123 INFO [user-service,64d3ee61d75f5c9c,64d3ee61d75f5c9c] UserController : User created successfully
```
Format: `[service-name,traceId,spanId]`

### Custom Spans (Optional)
```java
@NewSpan("custom-operation")
public void performOperation() {
    // Your code here
}
```

## Grafana Dashboards

### Pre-configured Dashboard
A microservices overview dashboard is automatically provisioned with:
- HTTP request rates
- Response times
- JVM memory usage
- Service health status

### Creating Custom Dashboards
1. Go to http://localhost:3000
2. Login with admin/admin
3. Create → Dashboard
4. Add panels with Prometheus queries

### Useful Prometheus Queries
```promql
# Request rate per service
rate(http_server_requests_seconds_count[5m])

# Average response time
rate(http_server_requests_seconds_sum[5m]) / rate(http_server_requests_seconds_count[5m])

# 95th percentile response time
histogram_quantile(0.95, http_server_requests_seconds_bucket)

# JVM memory usage percentage
jvm_memory_used_bytes / jvm_memory_max_bytes * 100

# Error rate
rate(http_server_requests_seconds_count{status=~"4..|5.."}[5m])
```

## Centralized Logging (ELK Stack)

### Log Format
All services use structured logging with trace correlation:
```
2024-01-15 10:30:00.123 INFO [user-service,traceId,spanId] com.example.UserController : User created: {"id": 1, "username": "john"}
```

### Logstash Configuration
- Parses Spring Boot log format
- Extracts trace IDs and service names
- Indexes logs in Elasticsearch
- Available at ports 5000 (TCP/UDP) and 5044 (Beats)

### Kibana Usage
1. Go to http://localhost:5601
2. Create index pattern: `microservices-logs-*`
3. Search and filter logs by:
   - Service name
   - Log level
   - Trace ID
   - Time range

### Log Shipping Options

#### Option 1: Filebeat (Recommended)
```yaml
# filebeat.yml
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/microservices/*.log
  fields:
    service: user-service

output.logstash:
  hosts: ["localhost:5044"]
```

#### Option 2: Logback Appender
Add to `logback-spring.xml`:
```xml
<appender name="LOGSTASH" class="net.logstash.logback.appender.LogstashTcpSocketAppender">
    <destination>localhost:5000</destination>
    <encoder class="net.logstash.logback.encoder.LoggingEventCompositeJsonEncoder">
        <providers>
            <timestamp/>
            <logLevel/>
            <loggerName/>
            <message/>
            <mdc/>
            <pattern>
                <pattern>{"service": "${spring.application.name}"}</pattern>
            </pattern>
        </providers>
    </encoder>
</appender>
```

## Alerting (Optional)

### Prometheus Alerts
Create `alerts.yml`:
```yaml
groups:
- name: microservices-alerts
  rules:
  - alert: HighErrorRate
    expr: rate(http_server_requests_seconds_count{status=~"5.."}[5m]) > 0.1
    for: 5m
    annotations:
      summary: "High error rate detected"
      
  - alert: HighMemoryUsage
    expr: jvm_memory_used_bytes / jvm_memory_max_bytes > 0.9
    for: 2m
    annotations:
      summary: "High memory usage detected"
```

### Grafana Alerts
1. Go to Alerting → Alert Rules
2. Create rules based on Prometheus queries
3. Set up notification channels (email, Slack, etc.)

## Performance Tuning

### Metrics Collection
```yaml
management:
  metrics:
    distribution:
      percentiles-histogram:
        http.server.requests: true
    tags:
      application: ${spring.application.name}
      environment: production
```

### Trace Sampling
For high-traffic services, reduce sampling:
```yaml
management:
  tracing:
    sampling:
      probability: 0.1  # Sample 10% of traces
```

## Troubleshooting

### Common Issues

1. **Metrics not appearing in Prometheus**
   - Check service health: `curl http://localhost:8081/actuator/health`
   - Verify Prometheus targets: http://localhost:9090/targets
   - Check firewall/network connectivity

2. **No traces in Zipkin**
   - Verify Zipkin is running: http://localhost:9411
   - Check application logs for tracing errors
   - Ensure sampling probability > 0

3. **Logs not in Elasticsearch**
   - Check Logstash pipeline status
   - Verify Elasticsearch is healthy: `curl http://localhost:9200/_cluster/health`
   - Check Logstash logs: `docker logs logstash`

### Health Checks
```bash
# Check all services
curl http://localhost:8761/actuator/health  # Discovery Server
curl http://localhost:8080/actuator/health  # API Gateway
curl http://localhost:8081/actuator/health  # Auth Service
curl http://localhost:8082/actuator/health  # User Service
curl http://localhost:8083/actuator/health  # Product Service

# Check monitoring stack
curl http://localhost:9090/-/healthy        # Prometheus
curl http://localhost:9411/health           # Zipkin
curl http://localhost:9200/_cluster/health  # Elasticsearch
```

## Production Considerations

### Security
- Enable authentication for Grafana, Kibana
- Use TLS for all connections
- Implement proper RBAC

### Scalability
- Use Prometheus federation for multiple clusters
- Implement log rotation and retention policies
- Consider using managed services (AWS CloudWatch, Azure Monitor)

### High Availability
- Run monitoring stack in cluster mode
- Implement backup strategies for metrics and logs
- Use external storage for Grafana dashboards

## Monitoring Endpoints Summary

| Service | Port | Health | Metrics | Dashboard |
|---------|------|--------|---------|-----------|
| Discovery Server | 8761 | `/actuator/health` | `/actuator/prometheus` | - |
| API Gateway | 8080 | `/actuator/health` | `/actuator/prometheus` | `/actuator/gateway/routes` |
| Auth Service | 8081 | `/actuator/health` | `/actuator/prometheus` | - |
| User Service | 8082 | `/actuator/health` | `/actuator/prometheus` | - |
| Product Service | 8083 | `/actuator/health` | `/actuator/prometheus` | - |
| Prometheus | 9090 | `/-/healthy` | - | Web UI |
| Grafana | 3000 | `/api/health` | - | Web UI |
| Zipkin | 9411 | `/health` | - | Web UI |
| Kibana | 5601 | `/api/status` | - | Web UI |
| Elasticsearch | 9200 | `/_cluster/health` | - | REST API |

This monitoring setup provides comprehensive observability for your microservices architecture, enabling you to monitor performance, troubleshoot issues, and maintain system health.
