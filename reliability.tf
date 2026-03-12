# PodDisruptionBudgets for cluster add-ons
# Ensures minimum availability during node drains and cluster upgrades

resource "kubernetes_manifest" "pdb_argocd_server" {
  depends_on = [helm_release.argocd]

  manifest = {
    apiVersion = "policy/v1"
    kind       = "PodDisruptionBudget"
    metadata = {
      name      = "argocd-server-pdb"
      namespace = "argocd"
    }
    spec = {
      minAvailable = 1
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "argocd-server"
        }
      }
    }
  }
}

resource "kubernetes_manifest" "pdb_argocd_repo_server" {
  depends_on = [helm_release.argocd]

  manifest = {
    apiVersion = "policy/v1"
    kind       = "PodDisruptionBudget"
    metadata = {
      name      = "argocd-repo-server-pdb"
      namespace = "argocd"
    }
    spec = {
      minAvailable = 1
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "argocd-repo-server"
        }
      }
    }
  }
}

resource "kubernetes_manifest" "pdb_kyverno_admission" {
  depends_on = [helm_release.kyverno]

  manifest = {
    apiVersion = "policy/v1"
    kind       = "PodDisruptionBudget"
    metadata = {
      name      = "kyverno-admission-pdb"
      namespace = "kyverno"
    }
    spec = {
      minAvailable = 1
      selector = {
        matchLabels = {
          "app.kubernetes.io/component" = "admission-controller"
        }
      }
    }
  }
}

resource "kubernetes_manifest" "pdb_prometheus" {
  depends_on = [helm_release.istio_prometheus]

  manifest = {
    apiVersion = "policy/v1"
    kind       = "PodDisruptionBudget"
    metadata = {
      name      = "prometheus-pdb"
      namespace = "monitoring"
    }
    spec = {
      minAvailable = 1
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "prometheus"
        }
      }
    }
  }
}

resource "kubernetes_manifest" "pdb_grafana" {
  depends_on = [helm_release.istio_prometheus]

  manifest = {
    apiVersion = "policy/v1"
    kind       = "PodDisruptionBudget"
    metadata = {
      name      = "grafana-pdb"
      namespace = "monitoring"
    }
    spec = {
      minAvailable = 1
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "grafana"
        }
      }
    }
  }
}