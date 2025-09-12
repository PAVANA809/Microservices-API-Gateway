#!/bin/bash

# Use health endpoint which is faster (no 5 second delay)
URL="http://192.168.56.104:8080/user-service/api/users/health"
TOKEN="eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJ0ZXN0dXNlcjEiLCJpYXQiOjE3NTc2NjU3NzAsImV4cCI6MTc1Nzc1MjE3MH0.HGNF_wA4zWp7QjERUVIuHuiTE33cGC2qeCtBGfG3nDGOFDg04nKGI82Uk3pVfdzfciCyOSNnkHHdcp2EXW4pbw"

echo "Testing rate limiting with rapid requests to health endpoint..."
echo "Expected: First 4 requests should pass (burst), then rate limited to 2/second"
echo ""

for i in {1..15}; do
    timestamp=$(date '+%H:%M:%S.%3N')
    response=$(curl -s -w "%{http_code}" -H "Authorization: Bearer $TOKEN" -X GET "$URL" -m 2)
    echo "[$timestamp] Request $i: HTTP $response"
    
    if [[ "$response" == *"429"* ]]; then
        echo "🚫 Rate limit triggered!"
    fi
    
    # No delay for rapid testing
done