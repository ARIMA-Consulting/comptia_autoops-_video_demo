#!/bin/bash
# CompTIA AutoOps+ | Zero-Downtime Deployment
# Exam Objective 4.1 — Delivery methods: Blue-green, Canary, Rolling, In-place


# ===========================================================================
# BLOCK 0 — Setup
#
# Zero-downtime means users never see an outage during a deployment.
# There are four main strategies — each trades off speed, cost, and risk.
#
#   In-place   : update the running server directly (DOWNTIME RISK)
#   Blue-Green : run two identical environments, switch traffic instantly
#   Rolling    : replace instances one at a time, always some running
#   Canary     : route a small % of traffic to new version, watch it, then roll out
# ===========================================================================

rm -rf deployment-demo
mkdir deployment-demo
cd deployment-demo

echo "v1.0" > current_version.txt
echo "Deployment demo ready."


# ===========================================================================
# BLOCK 1 — In-place deployment (the old way, has downtime risk)
#
# You stop the running app, replace the code, restart.
# During the stop→start window, users get errors.
# ===========================================================================

echo ""
echo "--- BLOCK 1: In-place deployment (downtime risk) ---"

cat > deploy_inplace.sh << 'EOF'
#!/bin/bash
echo "[In-Place] Stopping current app (users see downtime here)..."
sleep 0.5
echo "[In-Place] Replacing code with new version..."
echo "v2.0" > current_version.txt
sleep 0.5
echo "[In-Place] Restarting app..."
echo "[In-Place] Done. Version: $(cat current_version.txt)"
echo "[In-Place] Downtime window: ~1-2 minutes in production"
EOF

bash deploy_inplace.sh


# ===========================================================================
# BLOCK 2 — Blue-Green deployment
#
# Two identical environments: Blue (live) and Green (staging).
# Deploy to Green, test it, then flip the load balancer to point at Green.
# Rollback = flip the load balancer back to Blue. Instant.
# ===========================================================================

echo ""
echo "--- BLOCK 2: Blue-Green deployment ---"

cat > deploy_bluegreen.sh << 'EOF'
#!/bin/bash
echo "[Blue-Green] Current live environment: BLUE (v1.0)"
echo "[Blue-Green] Deploying v2.0 to GREEN environment..."
echo "v2.0" > green_version.txt
sleep 0.3

echo "[Blue-Green] Running smoke tests on GREEN..."
sleep 0.3
echo "[Blue-Green] GREEN is healthy."

echo "[Blue-Green] Switching load balancer: BLUE → GREEN"
cp green_version.txt current_version.txt
sleep 0.2

echo "[Blue-Green] Live environment is now: GREEN ($(cat current_version.txt))"
echo "[Blue-Green] BLUE is kept running as instant rollback target"
echo ""
echo "To roll back: cp blue_version.txt current_version.txt  (< 1 second)"
EOF

echo "v1.0" > blue_version.txt
bash deploy_bluegreen.sh


# ===========================================================================
# BLOCK 3 — Rolling deployment
#
# Update instances one at a time while others stay live.
# At no point is the entire service down.
# ===========================================================================

echo ""
echo "--- BLOCK 3: Rolling deployment (4 instances) ---"

cat > deploy_rolling.sh << 'EOF'
#!/bin/bash
INSTANCES=("instance-1" "instance-2" "instance-3" "instance-4")
NEW_VERSION="v2.0"

for instance in "${INSTANCES[@]}"; do
    echo "[Rolling] Updating $instance..."
    echo "[Rolling]   Remove from load balancer → update → health check → re-add"
    sleep 0.3
    echo "[Rolling]   $instance now running $NEW_VERSION ✓"
done

echo ""
echo "[Rolling] All instances updated to $NEW_VERSION with zero downtime"
EOF

bash deploy_rolling.sh


# ===========================================================================
# BLOCK 4 — Canary deployment
#
# Route a small percentage of traffic to the new version.
# Watch metrics (error rate, latency). If healthy, increase traffic gradually.
# If issues appear, route 100% back to old version — very few users were affected.
# ===========================================================================

echo ""
echo "--- BLOCK 4: Canary deployment ---"

cat > deploy_canary.py << 'EOF'
import time, random

def check_canary_health(error_rate_threshold=0.05):
    """Simulate canary health check — returns True if healthy."""
    simulated_error_rate = random.uniform(0.01, 0.03)   # 1-3% errors (healthy)
    print(f"  Canary error rate: {simulated_error_rate:.1%}  (threshold: {error_rate_threshold:.1%})")
    return simulated_error_rate < error_rate_threshold

canary_stages = [5, 25, 50, 100]   # % of traffic sent to new version

print("[Canary] Starting canary deployment of v2.0")
for traffic_pct in canary_stages:
    print(f"\n[Canary] Routing {traffic_pct}% of traffic to v2.0...")
    time.sleep(0.4)
    healthy = check_canary_health()
    if healthy:
        print(f"[Canary] Healthy at {traffic_pct}% — continuing rollout")
    else:
        print(f"[Canary] Unhealthy! Rolling back to v1.0")
        break
else:
    print("\n[Canary] 100% traffic on v2.0 — deployment complete")
EOF

python3 deploy_canary.py


# ===========================================================================
# BLOCK 5 — Kubernetes deployment strategies
#
# In Kubernetes, rolling updates are the DEFAULT — every kubectl apply
# replaces pods one at a time without taking the service down.
# These commands are what you use in production with a real cluster.
# (kubectl not required to run this block — it prints the commands for reference)
# ===========================================================================

echo ""
echo "--- BLOCK 5: kubectl deployment commands ---"
echo ""
echo "Rolling update (Kubernetes default):"
echo "  kubectl set image deployment/my-app app=my-app:v2.0"
echo "  kubectl rollout status deployment/my-app        # watch progress"
echo "  kubectl rollout undo deployment/my-app          # instant rollback"
echo ""
echo "Control rolling update speed (in the Deployment manifest):"
echo "  strategy:"
echo "    type: RollingUpdate"
echo "    rollingUpdate:"
echo "      maxUnavailable: 1   # at most 1 pod down at a time"
echo "      maxSurge: 1         # at most 1 extra pod during the update"
echo ""
echo "Canary in Kubernetes (split traffic with replicas):"
echo "  kubectl scale deployment my-app-v1 --replicas=9   # 90% traffic"
echo "  kubectl scale deployment my-app-v2 --replicas=1   # 10% canary"
echo "  # Watch error rates. If healthy:"
echo "  kubectl scale deployment my-app-v1 --replicas=0   # promote canary to 100%"
echo ""
echo "Blue-Green in Kubernetes (swap the Service selector):"
echo "  kubectl patch service my-app -p '{\"spec\":{\"selector\":{\"version\":\"v2\"}}}'"
echo "  # One command flips 100% of traffic — same concept as the script above"


# ===========================================================================
# BLOCK 6 — Summary: when to use each strategy
# ===========================================================================

echo ""
echo "=== Deployment strategy comparison ==="
echo ""
echo "In-place    : simplest, cheapest, HAS DOWNTIME — avoid for production"
echo "Blue-Green  : instant cutover + instant rollback, needs 2x infrastructure"
echo "Rolling     : no downtime, gradual, rollback is slower (Kubernetes default)"
echo "Canary      : safest for risky changes, catches issues before full rollout"
