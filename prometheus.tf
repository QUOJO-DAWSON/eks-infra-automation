resource "helm_release" "istio_prometheus" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "76.4.0"
  create_namespace = true
  namespace        = "monitoring"
  depends_on       = [helm_release.istiod]

  values = [
    <<-EOF
    prometheus:
      prometheusSpec:
        serviceMonitorSelectorNilUsesHelmValues: false

    alertmanager:
      config:
        global:
          resolve_timeout: 5m
          slack_api_url: "${var.slack_webhook_url}"

        route:
          group_by: ["alertname", "namespace", "severity"]
          group_wait: 30s
          group_interval: 5m
          repeat_interval: 4h
          receiver: "slack-warning"
          routes:
            - matchers:
                - severity = "critical"
              receiver: "slack-critical"
              continue: false
            - matchers:
                - severity = "warning"
              receiver: "slack-warning"
              continue: false

        receivers:
          - name: "slack-critical"
            slack_configs:
              - channel: "#alerts-critical"
                send_resolved: true
                icon_emoji: ":red_circle:"
                title: "[CRITICAL] {{ .GroupLabels.alertname }}"
                text: |
                  *Severity:* {{ .CommonLabels.severity | toUpper }}
                  *Namespace:* {{ .CommonLabels.namespace }}
                  *Summary:* {{ range .Alerts }}{{ .Annotations.summary }}{{ end }}
                  *Description:* {{ range .Alerts }}{{ .Annotations.description }}{{ end }}

          - name: "slack-warning"
            slack_configs:
              - channel: "#alerts-warning"
                send_resolved: true
                icon_emoji: ":warning:"
                title: "[WARNING] {{ .GroupLabels.alertname }}"
                text: |
                  *Severity:* {{ .CommonLabels.severity | toUpper }}
                  *Namespace:* {{ .CommonLabels.namespace }}
                  *Summary:* {{ range .Alerts }}{{ .Annotations.summary }}{{ end }}

          - name: "null"

        inhibit_rules:
          - source_matchers:
              - severity = "critical"
            target_matchers:
              - severity = "warning"
            equal: ["alertname", "namespace"]
    EOF
  ]
}