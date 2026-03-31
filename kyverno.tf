resource "helm_release" "kyverno" {
  name             = "kyverno"
  repository       = "https://kyverno.github.io/kyverno/"
  chart            = "kyverno"
  version          = "3.2.6"
  namespace        = "kyverno"
  create_namespace = true

  values = [
    <<-EOF
    admissionController:
      replicas: 1
    backgroundController:
      enabled: true
    reportsController:
      enabled: true
    EOF
  ]

  depends_on = [module.eks]
}