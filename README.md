# AWS Multi-Region Trading Platform (Scalability + HA) — IaC & Delivery

This repository is a **presentation-ready scaffold** that you can extend into production.
It includes:

- **Terraform/Terragrunt** for core AWS infrastructure (multi-region cells, EKS, TGW peering),
- **Helm charts** for containerized services in EKS (TB, RMS-Core, BFF) and Observability agents,
- **Argo CD Applications** for GitOps delivery per region/cell.

> Scope intentionally focuses on **Scalability** and **Multi-Region HA** (security left as placeholders).
> The code is a **starter template**: safe defaults, composable structure, and in-repo docs.

## High-Level
- **Per region** (cell): VPC, EKS (core plane), node groups, NLB, NATS JetStream, Aurora (placeholder), Redis (placeholder).
- **Cross region**: TGW inter-region peering, NATS leafnodes (values in Helm), global observability hub optional.
- **Ingress**: Global Accelerator → NLB → BFF (TCP/HTTP2). Frontend via CloudFront (placeholder).
- **Egress**: DX/VPN/Public (placeholders in Terraform with TODOs).

## Layout
```
infra/
  terragrunt/
    modules/               # Reusable Terraform modules
    live/                  # Region-specific instantiation
      region-a/
      region-b/
      hub-observability/
k8s/
  charts/                  # Helm charts for apps
    bff/
    rms-core/
    tb/
    nats-jetstream/        # wrapper values for upstream chart
    observability-agents/  # otel/prom-agent/promtail
argocd/
  applications/            # App-of-Apps per region
docs/
  OPERATIONS.md
  OBSERVABILITY.md
  SCALING_HA.md
```

## Quick Start
1. Fill variables in `infra/terragrunt/live/*/terragrunt.hcl` (AWS account/region, CIDRs).
2. `terragrunt run-all apply` from **each** live dir (or root with cautious inclusion).
3. Setup kubeconfig for each EKS cluster (per region).
4. Bootstrap Argo CD (manifests in `argocd/bootstrap/`), then apply App-of-Apps per region.
5. Tail dashboards & alerts *(see `docs/OBSERVABILITY.md`)*.

> This is an MVP scaffold: extend modules (Aurora, DX/VPN, CloudFront) and chart values for production.
