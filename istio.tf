# 1. Install istio-base first (CRDs and base components)
resource "helm_release" "istio-base" {
  name             = "istio-base"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "base"
  version          = "1.26.2"
  create_namespace = true
  namespace        = "istio-system"
  depends_on       = [module.eks, helm_release.aws-load-balancer-controller, helm_release.external-secrets]
}

