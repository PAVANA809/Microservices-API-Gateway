#!/bin/bash

# Use health endpoint which is faster (no 5 second delay)
URL="http://192.168.56.104:8080/user-service/api/users/loadtest"
TOKEN="eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJhZG1pbiIsImlhdCI6MTc1NzgyOTAxMiwiZXhwIjoxNzU3OTE1NDEyfQ.jO3Gk9jDcBs5A6NwuZxGl0j--sEQgfmzi6-3FGfcmuy0zF1j7uqY3PwMZG_6MZO7Z_42nRGlmUavKRS1xpFaLw"
echo "Testing rate limiting with rapid requests to health endpoint..."
echo "Expected: First 4 requests should pass (burst), then rate limited to 2/second"
echo ""

for i in {1..15}; do
    timestamp=$(date '+%H:%M:%S.%3N')
    response=$(curl -s -w "%{http_code}" -H "X-Request-Id: $RANDOM" -H "Authorization: Bearer $TOKEN" -X GET "$URL" -m 2)
    echo "[$timestamp] Request $i: HTTP $response"
    
    if [[ "$response" == *"429"* ]]; then
        echo "🚫 Rate limit triggered!"
    fi
    sleep 1
    # No delay for rapid testing
done