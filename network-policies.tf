resource "kubernetes_manifest" "netpol_default_deny" {
  depends_on = [kubernetes_namespace_v1.online-boutique]

  manifest = {
    apiVersion = "networking.k8s.io/v1"
    kind       = "NetworkPolicy"
    metadata = {
      name      = "default-deny-all"
      namespace = "online-boutique"
    }
    spec = {
      podSelector = {}
      policyTypes = ["Ingress", "Egress"]
    }
  }
}

resource "kubernetes_manifest" "netpol_allow_intra_namespace" {
  depends_on = [kubernetes_manifest.netpol_default_deny]

  manifest = {
    apiVersion = "networking.k8s.io/v1"
    kind       = "NetworkPolicy"
    metadata = {
      name      = "allow-intra-namespace"
      namespace = "online-boutique"
    }
    spec = {
      podSelector = {}
      policyTypes = ["Ingress", "Egress"]
      ingress = [
        {
          from = [
            {
              namespaceSelector = {
                matchLabels = {
                  "kubernetes.io/metadata.name" = "online-boutique"
                }
              }
            }
          ]
        }
      ]
      egress = [
        {
          to = [
            {
              namespaceSelector = {
                matchLabels = {
                  "kubernetes.io/metadata.name" = "online-boutique"
                }
              }
            }
          ]
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "netpol_allow_dns" {
  depends_on = [kubernetes_manifest.netpol_default_deny]

  manifest = {
    apiVersion = "networking.k8s.io/v1"
    kind       = "NetworkPolicy"
    metadata = {
      name      = "allow-dns-egress"
      namespace = "online-boutique"
    }
    spec = {
      podSelector = {}
      policyTypes = ["Egress"]
      egress = [
        {
          to = [
            {
              namespaceSelector = {
                matchLabels = {
                  "kubernetes.io/metadata.name" = "kube-system"
                }
              }
            }
          ]
          ports = [
            {
              port     = 53
              protocol = "UDP"
            },
            {
              port     = 53
              protocol = "TCP"
            }
          ]
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "netpol_allow_istio" {
  depends_on = [kubernetes_manifest.netpol_default_deny]

  manifest = {
    apiVersion = "networking.k8s.io/v1"
    kind       = "NetworkPolicy"
    metadata = {
      name      = "allow-istio-control-plane"
      namespace = "online-boutique"
    }
    spec = {
      podSelector = {}
      policyTypes = ["Ingress", "Egress"]
      ingress = [
        {
          from = [
            {
              namespaceSelector = {
                matchLabels = {
                  "kubernetes.io/metadata.name" = "istio-system"
                }
              }
            }
          ]
        }
      ]
      egress = [
        {
          to = [
            {
              namespaceSelector = {
                matchLabels = {
                  "kubernetes.io/metadata.name" = "istio-system"
                }
              }
            }
          ]
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "netpol_allow_prometheus" {
  depends_on = [kubernetes_manifest.netpol_default_deny]

  manifest = {
    apiVersion = "networking.k8s.io/v1"
    kind       = "NetworkPolicy"
    metadata = {
      name      = "allow-prometheus-scrape"
      namespace = "online-boutique"
    }
    spec = {
      podSelector = {}
      policyTypes = ["Ingress"]
      ingress = [
        {
          from = [
            {
              namespaceSelector = {
                matchLabels = {
                  "kubernetes.io/metadata.name" = "monitoring"
                }
              }
            }
          ]
          ports = [
            {
              port     = 9090
              protocol = "TCP"
            },
            {
              port     = 15090
              protocol = "TCP"
            }
          ]
        }
      ]
    }
  }
}