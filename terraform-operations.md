# Runbook: Terraform Operations

| Field | Value |
|-------|-------|
| **Component** | Terraform / EKS Infrastructure |
| **State Backend** | S3 with native state locking |
| **Last Updated** | 2024-10-15 |

---

## Quick Reference — Common Operations

| Operation | Jump To |
|-----------|---------|
| Deploy the cluster from scratch | [§ Full Deployment](#full-deployment-from-scratch) |
| Destroy the cluster cleanly | [§ Destroy Infrastructure](#destroy-infrastructure) |
| Recover from a stuck state lock | [§ State Lock Recovery](#state-lock-recovery) |
| Import an existing resource | [§ Importing Resources](#importing-existing-resources) |
| Upgrade EKS version | [§ EKS Version Upgrade](#eks-version-upgrade) |
| Recover from failed apply | [§ Failed Apply Recovery](#failed-apply-recovery) |
| Manage secrets safely | [§ Secrets Management](#secrets-management) |

---

## Prerequisites

```bash
# Verify tool versions
terraform version    # Must be >= 1.12.0
aws --version
kubectl version --client

# Confirm AWS identity
aws sts get-caller-identity

# Expected: the IAM role/user with permissions to create EKS, VPC, IAM resources
```

---

## Full Deployment From Scratch

Follow this sequence exactly. Skipping steps will cause dependency failures.

### Step 1 — Bootstrap the Terraform backend

Run the **Bootstrap Backend** GitHub Actions workflow (`workflow_dispatch`) once.

This creates:
- S3 bucket for Terraform state
- Native state locking (S3 versioning-based, no DynamoDB required)

> This workflow only needs to run once per AWS account. Do not re-run unless the bucket has been deleted.

### Step 2 — Set required GitHub Secrets

Ensure the following are set in your GitHub repository **Secrets**:

| Secret | Description |
|--------|-------------|
| `ADMIN_USER_ARN` | IAM user ARN for cluster admin access |
| `DEV_USER_ARN` | IAM user ARN for developer read-only access |
| `ACTIONS_AWS_ROLE_ARN` | IAM role ARN that GitHub Actions assumes via OIDC |

And in **Variables**:

| Variable | Value |
|----------|-------|
| `AWS_REGION` | e.g. `us-east-1` |

### Step 3 — Deploy

Push to `main` or trigger the **Deploy Infrastructure** workflow manually.

The workflow runs:
```
terraform init → terraform validate → terraform plan → terraform apply
```

Total time: approximately 12-15 minutes.

### Step 4 — Verify post-deployment

```bash
# Configure kubectl (replace with your values)
aws eks update-kubeconfig --region us-east-1 --name <cluster-name>

# Verify all nodes are Ready
kubectl get nodes

# Verify all add-on pods are Running
kubectl get pods -A | grep -v Running | grep -v Completed
# Should return nothing if all healthy

# Verify ArgoCD is synced
kubectl get applications -n argocd
```

---

## Destroy Infrastructure

Use the **Destroy Infrastructure** GitHub Actions workflow (`workflow_dispatch`).

> **Warning:** This is irreversible. All cluster resources, node groups, and VPC components will be deleted. Terraform state is preserved in S3.

### Manual destroy (if GitHub Actions is unavailable)

```bash
cd eks-infra-automation

# Assume the GitHub Actions IAM role or use a profile with sufficient permissions
export AWS_PROFILE=admin

terraform init
terraform destroy -auto-approve
```

### Post-destroy verification

```bash
# Confirm no EKS clusters remain
aws eks list-clusters --region us-east-1

# Confirm VPC is deleted
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=eks-platform" --region us-east-1
```

---

## State Lock Recovery

**Symptom:** `Error acquiring the state lock` when running `terraform apply` or `terraform plan`.

This happens when a previous Terraform run was interrupted and did not release the lock.

### Step 1 — Identify the lock

```bash
terraform init
terraform force-unlock <LOCK_ID>
```

The lock ID is shown in the error message:
```
Error: Error acquiring the state lock
Lock Info:
  ID: 12345678-abcd-...
```

### Step 2 — Force unlock

```bash
terraform force-unlock 12345678-abcd-...
# Confirm with: yes
```

### Step 3 — Verify state is consistent before re-applying

```bash
terraform plan
# Review carefully — ensure no unexpected destroy operations are shown
```

> Only force-unlock if you are certain no other `terraform apply` is running. Concurrent applies against the same state will cause corruption.

---

## Importing Existing Resources

If a resource was created manually in AWS and needs to be brought under Terraform management:

```bash
# General pattern
terraform import <resource_type>.<resource_name> <aws_resource_id>

# Examples:

# Import an existing EKS cluster
terraform import module.eks.aws_eks_cluster.this <cluster-name>

# Import an existing IAM role
terraform import aws_iam_role.external_admin <role-name>

# Import an existing S3 bucket
terraform import aws_s3_bucket.terraform_state <bucket-name>
```

After importing:
1. Run `terraform plan` — it should show no changes if the config matches the real resource.
2. If plan shows differences, update the Terraform config to match the imported resource before applying.

---

## EKS Version Upgrade

EKS minor version upgrades must be done in sequence (e.g., 1.31 → 1.32 → 1.33). Never skip versions.

### Step 1 — Update the variable

In `terraform.tfvars`:
```hcl
kubernetes_version = "1.33"   # increment by one minor version at a time
```

### Step 2 — Plan and review

```bash
terraform plan
```

Expected changes:
- `aws_eks_cluster` — version update (in-place)
- `aws_eks_node_group` — may show replacement (review carefully)

### Step 3 — Apply

```bash
terraform apply
```

EKS control plane upgrade takes approximately 10-15 minutes. Node groups are upgraded in a rolling fashion — existing workloads are not interrupted if PodDisruptionBudgets are configured.

### Step 4 — Verify

```bash
kubectl version
aws eks describe-cluster --name <cluster-name> --query "cluster.version"
kubectl get nodes  # confirm all nodes show the new version
```

---

## Failed Apply Recovery

**Symptom:** `terraform apply` partially completed and errored. State is inconsistent.

### Step 1 — Do not panic, do not re-run apply immediately

```bash
# Check what Terraform thinks exists
terraform state list

# Check what actually exists in AWS
aws eks list-clusters --region <region>
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=eks-platform"
```

### Step 2 — Identify the failed resource

The error output will name the specific resource. Common failures:

- **EKS cluster creation timeout** — cluster may still be creating; wait and re-run `terraform apply`
- **IAM role already exists** — import it (see [§ Importing Resources](#importing-existing-resources))
- **VPC limit reached** — check AWS service quotas and request an increase

### Step 3 — Remove a broken resource from state (if needed)

Only do this if the resource genuinely does not exist in AWS but is stuck in state:

```bash
terraform state rm <resource_address>
# Example:
terraform state rm aws_iam_role.external_admin
```

### Step 4 — Re-run apply

```bash
terraform apply
# Terraform will only act on resources that are missing or out of sync
```

---

## Secrets Management

**Never store secrets in `terraform.tfvars` or commit them to Git.**

Secrets (IAM ARNs, credentials) are passed via GitHub Actions Secrets and injected as environment variables at plan/apply time.

### Viewing current Terraform variable values (non-secret)

```bash
terraform console
> var.aws_region
> var.kubernetes_version
```

### Rotating a secret

1. Update the value in GitHub repository **Settings → Secrets and variables → Actions**
2. Re-run the **Deploy Infrastructure** workflow — Terraform will pick up the new value on the next `plan`/`apply`
3. If the secret is also stored in AWS Secrets Manager (e.g., ArgoCD credentials), update it there too — ESO will sync the new value to the cluster within one `refreshInterval` cycle (default: 1h)

---

## Useful Commands

```bash
# Show current state summary
terraform state list

# Show details of a specific resource
terraform state show aws_eks_cluster.this

# Validate config without connecting to AWS
terraform validate

# Format all .tf files
terraform fmt -recursive

# Generate a plan and save it
terraform plan -out=tfplan

# Apply a saved plan (no additional confirmation required)
terraform apply tfplan

# Target a single resource (use with caution)
terraform apply -target=helm_release.argocd

# Refresh state from real AWS resources (without applying)
terraform apply -refresh-only
```

---

## Cost Awareness

| Resource | Approximate Cost (us-east-1) |
|----------|------------------------------|
| EKS Control Plane | ~$0.10/hour (~$73/month) |
| t3.large node × 2 (desired) | ~$0.0832/hour each (~$121/month total) |
| NAT Gateway | ~$0.045/hour + data transfer |
| ALB | ~$0.008/hour + LCU charges |
| **Estimated total (running 24/7)** | **~$220-250/month** |

> **Recommendation:** Use the **Destroy Infrastructure** workflow when the cluster is not in active use to avoid unnecessary charges. Re-deploying from scratch takes ~12 minutes.
