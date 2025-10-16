# Operations

## Bring-up Order (per region)
1. VPC + Subnets + IGW/NAT + TGW attach
2. EKS Cluster + Node groups (core, nats-ssd)
3. NLB + GA endpoint (if using GA)
4. Argo CD bootstrap; apply App-of-Apps for region
5. Validate NATS JetStream quorum; deploy TB/RMS/BFF

## DR Drills
- AZ failure (node group drains)
- Regional evacuation (GA failover, NATS leafnode reconvergence)
- WAN provider flip (DX→VPN/NAT)
