# Observability Plan (Global Hub + Regional Edges)

- **Regional agents**: The `observability-agents` Helm chart now deploys Prometheus Agent, Promtail, and the OpenTelemetry Collector with hardened service accounts, RBAC, and default scrape/ship pipelines for cluster metrics, application logs, and OTLP traces. Override `values.yaml` per region to point at the hub Tempo, Loki, and Mimir endpoints.
- **Regional edges**: OTel Collector (metrics/logs/traces), Prometheus Agent, Alertmanager (HA). Use the provided network policies and service accounts to restrict lateral movement.
- **Global hub**: Grafana + Mimir + Loki + Tempo (in hub region). Remote write/push from edges over TGW.
- **SLOs**: ingestion lag Mimir p99≤10s, Loki≤30s, Tempo≤15s; query availability 99.9%.
- **Dashboards**: Hot path, RMS/NATS, WAN paths, EKS/Nodes, Storage.
- **Alerts**: TB tick→order drift, NATS JS lag, Aurora replica lag, DX/VPN loss, security policy violations.
- **Automation**: Use `scripts/drills/az-evacuate.sh` to test node evacuation and `scripts/drills/shift-traffic.sh` to programmatically move Global Accelerator traffic between regions.
