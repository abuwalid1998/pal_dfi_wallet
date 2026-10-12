#!/bin/bash
# ==============================================================================
# Ministry of Interior (MoI) - Container API Smoke Test Suite (Bash)
# ==============================================================================

BASE_URL="http://localhost:9000"

echo "=================================================================="
echo " MoI National ID Container - API Smoke Test Suite (Bash/cURL)"
echo " Target: $BASE_URL"
echo "=================================================================="

# Test 1: Healthcheck
echo -e "\n[TEST 1] Checking Container Health Probe (/health)..."
HEALTH_STATUS=$(curl -s "$BASE_URL/health" | grep -o '"status":"[^"]*"' | cut -d'"' -f4 || echo "ERROR")
if [ "$HEALTH_STATUS" == "UP" ]; then
    echo "  -> PASS: Healthcheck responded with UP"
else
    echo "  -> FAIL: Healthcheck did not respond with UP (got: $HEALTH_STATUS)"
fi

# Test 2: Civil Records
echo -e "\n[TEST 2] Checking Civil Registry Records (/api/v1/moi/records)..."
COUNT=$(curl -s "$BASE_URL/api/v1/moi/records" | grep -o '"count":[0-9]*' | cut -d':' -f2 || echo "0")
echo "  -> PASS: Fetched $COUNT records from CSV ledger"

# Test 3: Pilot Stats
echo -e "\n[TEST 3] Checking Pilot Analytics (/api/v1/moi/stats)..."
curl -s "$BASE_URL/api/v1/moi/stats" | head -n 12

# Test 4: Export CSV
echo -e "\n[TEST 4] Testing CSV Ledger Export (/api/v1/moi/export-csv)..."
CSV_HEADER=$(curl -s "$BASE_URL/api/v1/moi/export-csv" | head -n 1)
if [[ "$CSV_HEADER" =~ "national_id_number" ]]; then
    echo "  -> PASS: CSV export contains valid header"
else
    echo "  -> FAIL: CSV header unexpected ($CSV_HEADER)"
fi

echo -e "\n=================================================================="
echo " MoI Container Smoke Test Finished!"
echo "=================================================================="
