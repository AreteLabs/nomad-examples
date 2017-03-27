job "spark" {
  datacenters = ["dc1"]

  constraint {
    attribute = "${node.class}"
    value     = "node"
  }

  task "spark-ui" {
    driver = "docker"

    config {
      image = "ursuad/spark-ui-proxy"

      args = [
        "spark-master-webui.service.consul:4809",
        "${NOMAD_PORT_webui}",
      ]

      dns_servers = ["${attr.unique.network.ip-address}"]
    }

    service {
      name = "spark-webui"
      tags = ["spark-webui", "traefik.enable=true", "traefik.frontend.rule=Host:spark.10.244.234.64.sslip.io"]

      port = "webui"

      check {
        type     = "http"
        path     = "/"
        port     = "webui"
        interval = "10s"
        timeout  = "2s"
      }
    }

    resources {
      cpu    = 200
      memory = 100

      network {
        mbits = 50

        port "webui" {
        }
      }
    }
  }

  task "master" {
    driver = "docker"

    config {
      image = "gettyimages/spark"

      volumes = [
        "local/data:/tmp/data",
      ]

      command = "bin/spark-class"

      args = [
        "org.apache.spark.deploy.master.Master",
      ]

      dns_servers = ["${attr.unique.network.ip-address}"]
    }

    env {
      SPARK_PUBLIC_DNS        = "spark-master-webui.service.consul"
      SPARK_MASTER_WEBUI_PORT = "${NOMAD_PORT_webui}"
    }

    service {
      name = "spark-master-webui"
      tags = ["spark-master"]

      port = "webui"

      check {
        type     = "http"
        path     = "/"
        port     = "webui"
        interval = "10s"
        timeout  = "2s"
      }
    }

    resources {
      cpu    = 500
      memory = 500

      network {
        mbits = 50

        port "webui" {
          static = 4809
        }

        port "master" {
          static = 7077
        }
      }
    }
  }

  group "slaves" {
    task "slave" {
      driver = "docker"

      config {
        image = "gettyimages/spark"

        volumes = [
          "local/data:/tmp/data",
        ]

        command = "bin/spark-class"

        args = [
          "org.apache.spark.deploy.worker.Worker",
          "spark://spark-master-webui.service.consul:7077",
        ]

        dns_servers = ["${NOMAD_IP_webui}"]
      }

      env {
        SPARK_PUBLIC_DNS        = "spark-slave-webui-${NOMAD_ALLOC_INDEX}.service.consul"
        SPARK_WORKER_WEBUI_PORT = "${NOMAD_PORT_webui}"
      }

      service {
        name = "spark-slave-webui-${NOMAD_ALLOC_INDEX}"
        tags = ["spark-slave"]

        port = "webui"

        check {
          type     = "http"
          path     = "/"
          port     = "webui"
          interval = "10s"
          timeout  = "2s"
        }
      }

      resources {
        cpu    = 500
        memory = 500

        network {
          mbits = 50

          port "webui" {
          }
        }
      }
    }
  }
}