resource "time_sleep" "wait_for_kyverno_crds" {
  depends_on      = [helm_release.kyverno]
  create_duration = "30s"
}

resource "kubernetes_manifest" "policy_disallow_privileged" {
  depends_on = [time_sleep.wait_for_kyverno_crds]

  manifest = {
    apiVersion = "kyverno.io/v1"
    kind       = "ClusterPolicy"
    metadata = {
      name = "disallow-privileged-containers"
      annotations = {
        "policies.kyverno.io/title"       = "Disallow Privileged Containers"
        "policies.kyverno.io/severity"    = "high"
        "policies.kyverno.io/description" = "Privileged containers have access to all Linux kernel capabilities and can escape container isolation. This policy disallows privileged containers."
      }
    }
    spec = {
      validationFailureAction = "Enforce"
      background              = true
      rules = [
        {
          name = "check-privileged"
          match = {
            any = [
              {
                resources = {
                  kinds = ["Pod"]
                }
              }
            ]
          }
          validate = {
            message = "Privileged containers are not allowed."
            pattern = {
              spec = {
                containers = [
                  {
                    "=(securityContext)" = {
                      "=(privileged)" = false
                    }
                  }
                ]
              }
            }
          }
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "policy_require_non_root" {
  depends_on = [time_sleep.wait_for_kyverno_crds]

  manifest = {
    apiVersion = "kyverno.io/v1"
    kind       = "ClusterPolicy"
    metadata = {
      name = "require-non-root-user"
      annotations = {
        "policies.kyverno.io/title"       = "Require Non-Root User"
        "policies.kyverno.io/severity"    = "medium"
        "policies.kyverno.io/description" = "Containers must not run as root. This policy requires runAsNonRoot to be set to true."
      }
    }
    spec = {
      validationFailureAction = "Enforce"
      background              = true
      rules = [
        {
          name = "check-non-root"
          match = {
            any = [
              {
                resources = {
                  kinds      = ["Pod"]
                  namespaces = ["online-boutique"]
                }
              }
            ]
          }
          validate = {
            message = "Containers must not run as root. Set securityContext.runAsNonRoot=true."
            pattern = {
              spec = {
                containers = [
                  {
                    securityContext = {
                      runAsNonRoot = true
                    }
                  }
                ]
              }
            }
          }
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "policy_require_resource_limits" {
  depends_on = [time_sleep.wait_for_kyverno_crds]

  manifest = {
    apiVersion = "kyverno.io/v1"
    kind       = "ClusterPolicy"
    metadata = {
      name = "require-resource-limits"
      annotations = {
        "policies.kyverno.io/title"       = "Require Resource Limits"
        "policies.kyverno.io/severity"    = "medium"
        "policies.kyverno.io/description" = "Resource limits prevent containers from consuming excessive CPU and memory. This policy requires all containers to have resource limits defined."
      }
    }
    spec = {
      validationFailureAction = "Audit"
      background              = true
      rules = [
        {
          name = "check-resource-limits"
          match = {
            any = [
              {
                resources = {
                  kinds      = ["Pod"]
                  namespaces = ["online-boutique"]
                }
              }
            ]
          }
          validate = {
            message = "Resource limits for CPU and memory are required."
            pattern = {
              spec = {
                containers = [
                  {
                    resources = {
                      limits = {
                        cpu    = "?*"
                        memory = "?*"
                      }
                    }
                  }
                ]
              }
            }
          }
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "policy_disallow_latest_tag" {
  depends_on = [time_sleep.wait_for_kyverno_crds]

  manifest = {
    apiVersion = "kyverno.io/v1"
    kind       = "ClusterPolicy"
    metadata = {
      name = "disallow-latest-tag"
      annotations = {
        "policies.kyverno.io/title"       = "Disallow Latest Tag"
        "policies.kyverno.io/severity"    = "medium"
        "policies.kyverno.io/description" = "The latest tag is mutable and can cause unexpected behaviour. This policy disallows images using the latest tag."
      }
    }
    spec = {
      validationFailureAction = "Enforce"
      background              = true
      rules = [
        {
          name = "check-image-tag"
          match = {
            any = [
              {
                resources = {
                  kinds      = ["Pod"]
                  namespaces = ["online-boutique"]
                }
              }
            ]
          }
          validate = {
            message = "Using the latest tag is not allowed. Specify a concrete image tag."
            pattern = {
              spec = {
                containers = [
                  {
                    image = "!*:latest"
                  }
                ]
              }
            }
          }
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "policy_disallow_host_namespaces" {
  depends_on = [time_sleep.wait_for_kyverno_crds]

  manifest = {
    apiVersion = "kyverno.io/v1"
    kind       = "ClusterPolicy"
    metadata = {
      name = "disallow-host-namespaces"
      annotations = {
        "policies.kyverno.io/title"       = "Disallow Host Namespaces"
        "policies.kyverno.io/severity"    = "high"
        "policies.kyverno.io/description" = "Host namespaces (PID, IPC, network) allow containers to access shared host-level resources. This policy disallows the use of host namespaces."
      }
    }
    spec = {
      validationFailureAction = "Enforce"
      background              = true
      rules = [
        {
          name = "check-host-namespaces"
          match = {
            any = [
              {
                resources = {
                  kinds = ["Pod"]
                }
              }
            ]
          }
          exclude = {
            any = [
              {
                resources = {
                  kinds      = ["Pod"]
                  namespaces = ["monitoring", "kube-system", "istio-system", "istio-ingress"]
                }
              }
            ]
          }
          validate = {
            message = "Host namespaces (hostPID, hostIPC, hostNetwork) are not allowed."
            pattern = {
              spec = {
                "=(hostPID)"     = false
                "=(hostIPC)"     = false
                "=(hostNetwork)" = false
              }
            }
          }
        }
      ]
    }
  }
}
