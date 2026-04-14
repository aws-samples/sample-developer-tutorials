# ELB: Create an Application Load Balancer

Create an Application Load Balancer with a security group, target group, and HTTP listener using the default VPC.

## Source

https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancer-getting-started.html

## Use case

- **ID**: elbv2/getting-started
- **Level**: intermediate
- **Core actions**: `elbv2:CreateLoadBalancer`, `elbv2:CreateListener`, `elbv2:CreateTargetGroup`

## Steps

1. Get VPC and subnets
2. Create a security group
3. Create a target group
4. Create the Application Load Balancer
5. Wait for ALB to be active
6. Create an HTTP listener
7. Describe the ALB

## Resources created

| Resource | Type |
|----------|------|
| `tut-alb-<random>` | Application Load Balancer |
| `tut-tg-<random>` | Target group |
| `tut-alb-sg-<random>` | Security group |
| HTTP listener on port 80 | Listener |

## Duration

~121 seconds (most time spent waiting for ALB provisioning)

## Cost

~$0.02/hr while the ALB is running. Clean up promptly to avoid charges.

## Related docs

- [Getting started with Application Load Balancers](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancer-getting-started.html)
- [Create an Application Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-application-load-balancer.html)
- [Target groups for ALBs](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html)
- [Elastic Load Balancing pricing](https://aws.amazon.com/elasticloadbalancing/pricing/)

---

## Appendix

| Field | Value |
|-------|-------|
| Date | 2026-04-14 |
| Script lines | 112 |
| Exit code | 0 |
| Runtime | 121s |
| Steps | 7 |
| Issues | None |
| Version | v1 |
