# Load Balancing Test Scripts

This directory contains comprehensive load balancing test scripts for the Microservices API Gateway project.

## 📁 Files Overview

### Main Scripts
- **`test-load-balancing.sh`** - Main load balancing test script
- **`setup-load-test.sh`** - Environment setup helper
- **`cleanup-load-test.sh`** - Post-test cleanup script

## 🚀 Quick Start

### 1. Prepare Environment
```bash
./setup-load-test.sh
```

### 2. Run Load Balancing Tests
```bash
./test-load-balancing.sh
```

### 3. Clean Up After Testing
```bash
./cleanup-load-test.sh
```

## 🧪 Test Types

### Option 1: Quick Test
- Uses existing single service instances
- Tests basic load balancing functionality
- No additional setup required
- Good for development and CI/CD

### Option 2: Multiple Instance Test
- Starts multiple instances of selected services
- Tests true load distribution across instances
- Demonstrates horizontal scaling
- **Recommended for comprehensive testing**

### Option 3: Concurrent Load Test
- Tests system under concurrent user load
- Measures response times and success rates
- Good for performance benchmarking

### Option 4: Full Comprehensive Test
- Combines multiple instance and concurrent testing
- Most thorough load balancing validation
- Includes detailed statistics and analysis

### Option 5: Test Existing Instances
- Tests currently running service instances
- Good for quick validation without setup

## 📊 Test Features

### Load Distribution Analysis
- **Request Distribution**: Shows how requests are distributed across instances
- **Balance Verification**: Checks if load is evenly distributed
- **Instance Identification**: Tracks which instance handled each request

### Performance Metrics
- **Response Times**: Min, max, and average response times
- **Success Rates**: Percentage of successful requests
- **Throughput**: Requests per second measurements
- **Concurrent Users**: Simulation of multiple users

### Eureka Integration
- **Service Discovery**: Verifies instances are registered in Eureka
- **Instance Health**: Checks instance health status
- **Dynamic Scaling**: Tests addition/removal of instances

## 🔧 Configuration

### Environment Variables
```bash
API_HOST=localhost          # API Gateway host
GATEWAY_PORT=8080          # API Gateway port
DISCOVERY_URL=http://localhost:8761  # Eureka server URL
```

### Test Parameters
- **Request Count**: Number of requests per test (default: 20-30)
- **Concurrent Users**: Number of simultaneous users (default: 5)
- **Instance Count**: Number of service instances to start (default: 3)

## 📈 Understanding Results

### Load Distribution Results
```
Request | Status | Response Time | Instance Info
--------|--------|---------------|---------------
      1 |    200 |         0.234s | user-service-1
      2 |    200 |         0.187s | user-service-2
      3 |    200 |         0.201s | user-service-3
```

### Distribution Summary
```
Total Requests: 30
Successful: 30
Failed: 0
Success Rate: 100.00%

Requests per Instance:
  user-service-1      : 10 requests (33.3%)
  user-service-2      : 10 requests (33.3%)  
  user-service-3      : 10 requests (33.3%)
```

### What Good Results Look Like
✅ **Balanced Distribution**: Requests evenly spread across instances  
✅ **High Success Rate**: >95% successful requests  
✅ **Consistent Response Times**: Low variance in response times  
✅ **All Instances Used**: All registered instances receive requests  

### Warning Signs
⚠️ **Uneven Distribution**: One instance handling most requests  
⚠️ **High Error Rate**: >5% failed requests  
⚠️ **High Response Times**: Significant delays or timeouts  
⚠️ **Single Instance**: Load balancer not distributing load  

## 🔍 Monitoring During Tests

### Real-time Monitoring
```bash
# Watch service status
watch ./service-manager.sh status all

# Monitor logs
tail -f logs/multi-instance/*.log

# Check Eureka dashboard
firefox http://localhost:8761
```

### System Resources
```bash
# Monitor CPU usage
htop

# Monitor memory
watch free -h

# Monitor network
netstat -tuln | grep :808
```

## 🐛 Troubleshooting

### Common Issues

#### Load Balancing Not Working
```
Problem: All requests go to single instance
Solution: 
- Check Eureka registration: http://localhost:8761
- Verify Spring Cloud LoadBalancer is enabled
- Check API Gateway routing configuration
```

#### High Error Rates
```
Problem: Many 5xx errors during testing
Solution:
- Check service logs for errors
- Verify adequate system resources
- Reduce concurrent load
- Check database connections
```

#### Instances Not Starting
```
Problem: Multiple instances fail to start
Solution:
- Check port availability
- Verify Java/Maven installation
- Check service dependencies
- Review application.yml configuration
```

### Debug Commands
```bash
# Check running Java processes
jps -l

# Check port usage
netstat -tulpn | grep :80

# Check service logs
tail -f logs/discovery-server.log
tail -f logs/api-gateway.log

# Test direct service access
curl http://localhost:8761/eureka/apps
```

## 📚 Advanced Usage

### Custom Load Patterns
Modify the test script to implement custom load patterns:
```bash
# Burst load pattern
for i in {1..50}; do
    curl "$endpoint" &
done
wait

# Gradual ramp-up
for users in {1..10}; do
    test_concurrent_load "$endpoint" $users 5
    sleep 10
done
```

### Integration with CI/CD
```yaml
# Example GitHub Actions workflow
- name: Load Balancing Test
  run: |
    ./start-services.sh
    sleep 30
    ./test-load-balancing.sh <<< "5"
    ./cleanup-load-test.sh <<< "n"
```

### Performance Benchmarking
```bash
# Record baseline performance
./test-load-balancing.sh > baseline-results.txt

# Compare with changes
./test-load-balancing.sh > new-results.txt
diff baseline-results.txt new-results.txt
```

## 🏗️ Architecture Notes

### Load Balancing Algorithm
- **Default**: Round-robin distribution
- **Configurable**: Can be changed in Spring Cloud LoadBalancer configuration
- **Health-aware**: Automatically excludes unhealthy instances

### Service Discovery Integration
- **Registration**: Services register with Eureka on startup
- **Health Checks**: Eureka monitors instance health
- **Dynamic Updates**: Load balancer updates instance list automatically

### Scaling Considerations
- **Horizontal Scaling**: Add more service instances
- **Resource Limits**: Monitor CPU, memory usage
- **Database Connections**: Ensure adequate connection pools
- **Network Bandwidth**: Consider network capacity

## 📋 Best Practices

### Testing Best Practices
1. **Start Simple**: Use existing instances first
2. **Incremental Testing**: Gradually increase load
3. **Monitor Resources**: Watch CPU, memory, disk I/O
4. **Baseline First**: Record normal performance
5. **Clean Environment**: Use fresh instances for accurate results

### Production Considerations
1. **Circuit Breakers**: Implement fault tolerance
2. **Rate Limiting**: Protect against overload
3. **Health Checks**: Robust health monitoring
4. **Graceful Shutdown**: Handle instance restarts properly
5. **Monitoring**: Continuous performance monitoring

## 🤝 Contributing

To add new test scenarios:
1. Modify `test-load-balancing.sh`
2. Add new test functions following existing patterns
3. Update this documentation
4. Test with various load patterns
5. Submit pull request with test results

## 📞 Support

For issues or questions:
1. Check service logs first
2. Verify Eureka dashboard
3. Review system resources
4. Check network connectivity
5. Consult Spring Cloud documentation
