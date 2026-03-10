"""
SRE Demo Metrics App
Emits Prometheus metrics representing a production service
that is slightly below its 99.9% uptime SLO.
After ~1 minute the alert rules will fire — visible at localhost:9090/alerts
and in Alertmanager at localhost:9093.
"""
from prometheus_client import start_http_server, Gauge, Counter
import time, random

# SLI metrics — these are what SREs actually query in Prometheus
uptime_pct     = Gauge('service_uptime_pct',       'Rolling 30-day uptime %')
error_rate_pct = Gauge('service_error_rate_pct',   'HTTP error rate %')
p95_latency_ms = Gauge('service_p95_latency_ms',   'P95 request latency ms')
budget_min_rem = Gauge('service_error_budget_min', 'Error budget minutes remaining')

requests_total = Counter('service_requests_total', 'HTTP requests', ['status_code'])

def update():
    # 99.84% uptime — 9 min below the 99.9% SLO (will trigger SLOBreached alert)
    uptime_pct.set(99.84)
    error_rate_pct.set(0.8)
    p95_latency_ms.set(520)   # over the 500ms SLO
    budget_min_rem.set(-9.0)  # budget EXHAUSTED by 9 minutes

    for _ in range(random.randint(40, 80)):
        if random.random() < 0.008:
            requests_total.labels(status_code='500').inc()
        else:
            requests_total.labels(status_code='200').inc()

if __name__ == '__main__':
    start_http_server(8000)
    print("SRE metrics app running — http://localhost:8766/metrics")
    while True:
        update()
        time.sleep(5)
