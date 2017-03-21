job "queues" {
  datacenters = ["dc1"]

  constraint {
    attribute = "${node.class}"
    value     = "node"
  }

  group "zookeepers" {
    constraint {
      distinct_hosts = true
    }

    task "zookeeper" {
      driver = "docker"

      config {
        image       = "wurstmeister/zookeeper"
        dns_servers = ["${NOMAD_IP_zk}"]
      }

      service {
        name = "kafka-zk"
        tags = ["kafka-zk"]

        port = "zk"

        check {
          type     = "tcp"
          port     = "zk"
          interval = "10s"
          timeout  = "2s"
        }
      }

      resources {
        cpu    = 100
        memory = 100

        network {
          mbits = 50

          port "zk" {
            static = 2181
          }
        }
      }
    }
  }

  group "kafkas" {
    task "kafka" {
      driver = "docker"

      config {
        image       = "wurstmeister/kafka"
        dns_servers = ["${NOMAD_IP_port}"]

        port_map {
          port = 9092
        }
      }

      env {
        KAFKA_ADVERTISED_PORT      = "${NOMAD_PORT_port}"
        KAFKA_ADVERTISED_HOST_NAME = "${NOMAD_IP_port}"
        KAFKA_ZOOKEEPER_CONNECT    = "kafka-zk.service.consul:2181"
      }

      service {
        name = "kafka"
        tags = ["kafka"]

        port = "port"

        check {
          type     = "tcp"
          port     = "port"
          interval = "10s"
          timeout  = "2s"
        }
      }

      resources {
        cpu    = 300
        memory = 300

        network {
          mbits = 50

          port "port" {
          }
        }
      }
    }
  }
}