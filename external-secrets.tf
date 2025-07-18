module "external_secrets_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.59"

  role_name                      = "${var.project_name}-external-secrets-irsa"
  attach_external_secrets_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["external-secrets-system:external-secrets"]
    }
  }

  tags = {
    "Environment" = "dev"
    "Terraform"   = "true"
  }
}

resource "helm_release" "external-secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = "0.18.2"
  create_namespace = true
  namespace        = "external-secrets-system"
  depends_on       = [module.eks, helm_release.aws-load-balancer-controller, module.external_secrets_irsa]

  wait = true

  set = [
    {
      name  = "serviceAccount.create"
      value = "true"
    },
    {
      name  = "serviceAccount.name"
      value = "external-secrets"
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = module.external_secrets_irsa.iam_role_arn
    }
  ]
}