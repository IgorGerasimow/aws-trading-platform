# Observability Plan (Global Hub + Regional Edges)

- **Regional edges**: OTel Collector (metrics/logs/traces), Prometheus Agent, Alertmanager (HA).
- **Global hub**: Grafana + Mimir + Loki + Tempo (in hub region). Remote write/push from edges over TGW.
- **SLOs**: ingestion lag Mimir p99≤10s, Loki≤30s, Tempo≤15s; query availability 99.9%.
- **Dashboards**: Hot path, RMS/NATS, WAN paths, EKS/Nodes, Storage.
- **Alerts**: TB tick→order drift, NATS JS lag, Aurora replica lag, DX/VPN loss, security policy violations.
