job "lb" {
  datacenters = ["dc1"]

  constraint {
    attribute = "${node.class}"
    value     = "loadbalancer"
  }

  task "traefik" {
    driver = "docker"

    artifact {
      source      = "git::http://github.com/AreteLabs/nomad-examples"
      destination = "local/config"
    }

    template {
      source      = "local/config/traefik/traefik.toml"
      destination = "local/traefik/traefik.toml"
    }

    config {
      image = "traefik"

      volumes = [
        "local/traefik:/etc/traefik",
      ]

      args = [
        "--web",
      ]

      port_map {
        admin    = 8080
        frontend = 80
      }

      dns_servers = ["${NOMAD_IP_admin}"]
    }

    service {
      name = "traefik-admin"
      tags = ["loadbalancer", "admin", "traefik.enable=true", "traefik.frontend.rule=Host:admin.10.244.234.64.sslip.io"]

      port = "admin"

      check {
        type     = "tcp"
        port     = "admin"
        interval = "10s"
        timeout  = "2s"
      }
    }

    service {
      name = "traefik-frontend"
      tags = ["loadbalancer", "frontend"]

      port = "frontend"

      check {
        type     = "tcp"
        port     = "frontend"
        interval = "10s"
        timeout  = "2s"
      }
    }

    resources {
      cpu    = 200
      memory = 200

      network {
        mbits = 50

        port "admin" {
        }

        port "frontend" {
          static = "80"
        }
      }
    }
  }
}