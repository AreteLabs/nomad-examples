job "scope-app" {
  constraint {
    attribute = "${node.class}"
    value     = "node"
  }

  datacenters = ["dc1"]

  task "scope-app" {
    driver = "docker"

    config {
      image = "weaveworks/scope:1.3.0"

      args = ["--no-probe"]

      port_map {
        web = 4040
      }

      dns_servers = ["${attr.unique.network.ip-address}"]
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

    env {
      SCOPE_HOSTNAME = "${node.unique.name}"
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