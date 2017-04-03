job "scope-agent" {
  datacenters = ["dc1"]

  type = "system"

  task "scope-agent" {
    driver = "docker"

    config {
      image = "weaveworks/scope:1.2.1"

      privileged = true

      args = ["--probe.docker=true", "--no-app", "scope-app.service.consul"]

      pid_mode     = "host"
      network_mode = "host"

      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock:rw",
      ]

      dns_servers = ["${attr.unique.network.ip-address}"]
    }

    env {
      SCOPE_HOSTNAME = "${node.unique.name}"
    }

    resources {
      cpu    = 100
      memory = 100

      network {
        mbits = 50
      }
    }
  }
}