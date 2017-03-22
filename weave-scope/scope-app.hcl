job "scope-app" {
  constraint {
    attribute = "${node.class}"
    value     = "node"
  }

  datacenters = ["dc1"]

  task "scope-app" {
    driver = "docker"

    config {
      image = "weaveworks/scope:1.2.1"

      args = ["--no-probe"]

      port_map {
        web = 4040
      }

      dns_servers = ["${NOMAD_IP_web}"]
    }

    service {
      name = "scope-app"
      tags = ["scope-app", "traefik.enable=true", "traefik.frontend.rule=Host:scope.10.244.234.64.sslip.io"]

      port = "web"

      check {
        type     = "tcp"
        port     = "web"
        interval = "10s"
        timeout  = "2s"
      }
    }

    resources {
      cpu    = 300
      memory = 300

      network {
        mbits = 50

        port "web" {
          static = 4040
        }
      }
    }
  }
}