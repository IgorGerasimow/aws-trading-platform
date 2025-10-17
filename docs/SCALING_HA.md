# Scalability & HA Cheatsheet

- **Cell per region**. No hot-path cross-region calls. Async replication via NATS leafnodes.
- **UL-latency plane**: TB + RMS-Agent + Order GW on tuned EC2 node group (hostNetwork, placement groups).
- **Core plane**: EKS runs RMS-Core, BFF, NATS JetStream, observability agents.
- **Ingress**: Global Accelerator → NLB → BFF. 
- **Egress (TB only)**: prefer DX > VPN-A > VPN-B > NAT. Specific routes via TGW.
- **Data plane**: Aurora Global Database module provided; extend with Dynamo/Redis as needed. S3 for history.
- **Autoscaling**: HPA for apps, Karpenter/CA for nodes, warm pools for TB sessions.
