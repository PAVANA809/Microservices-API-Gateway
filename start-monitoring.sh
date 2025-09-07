#!/bin/bash

# Microservices Monitoring Stack Startup Script

echo "🚀 Starting Microservices Monitoring Stack..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Check if docker compose is available
if ! docker compose version &> /dev/null; then
    echo "❌ docker compose is not available. Please install Docker Compose V2."
    exit 1
fi

echo "📊 Starting monitoring services..."

# Start the monitoring stack
docker compose -f docker-compose-monitoring.yml up -d

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 30

# Check service status
echo "🔍 Checking service status..."

services=(
    "prometheus:9090"
    "grafana:3000"
    "zipkin:9411"
    "elasticsearch:9200"
    "kibana:5601"
    "redis:6379"
)

for service in "${services[@]}"; do
    IFS=':' read -r name port <<< "$service"
    if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$port" | grep -q "200\|302"; then
        echo "✅ $name is running on port $port"
    else
        echo "⚠️  $name may not be ready yet on port $port"
    fi
done

echo ""
echo "🎉 Monitoring stack startup complete!"
echo ""
echo "📈 Access your monitoring tools:"
echo "   Prometheus:     http://localhost:9090"
echo "   Grafana:        http://localhost:3000 (admin/admin)"
echo "   Zipkin:         http://localhost:9411"
echo "   Kibana:         http://localhost:5601"
echo "   Elasticsearch:  http://localhost:9200"
echo ""
echo "🔧 Next steps:"
echo "   1. Start your microservices"
echo "   2. Generate some traffic"
echo "   3. View metrics in Grafana"
echo "   4. Check traces in Zipkin"
echo "   5. Search logs in Kibana"
echo ""
echo "📋 To stop the monitoring stack:"
echo "   docker compose -f docker-compose-monitoring.yml down"
