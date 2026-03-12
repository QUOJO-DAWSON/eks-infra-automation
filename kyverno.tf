resource "helm_release" "kyverno" {
  name             = "kyverno"
  repository       = "https://kyverno.github.io/kyverno/"
  chart            = "kyverno"
  version          = "3.2.6"
  namespace        = "kyverno"
  create_namespace = true

  set {
    name  = "admissionController.replicas"
    value = "1"
  }

  set {
    name  = "backgroundController.enabled"
    value = "true"
  }

  set {
    name  = "reportsController.enabled"
    value = "true"
  }

  depends_on = [module.eks]
}