terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
      version = "0.51.1"
    }
    # docker = {
    #   source = "kreuzwerker/docker"
    #   version = "2.11.0"
    # }
  }
}

provider "yandex" {
  service_account_key_file = "./key.json"
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = "ru-central1-a"
}

# provider "docker" {
#   alias  = "bulder"
#   host = "tcp://${yandex_compute_instance.vm-1.network_interface.0.nat_ip_address}:2376/"
# }

# provider "docker" {
#   alias  = "deployer"
#   host = "tcp://${yandex_compute_instance.vm-2.network_interface.0.nat_ip_address}:2376/"
# }

resource "yandex_compute_instance" "vm-1" {
  name = "terraform1"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8vmcue7aajpmeo39kk"
      size = 20
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("./id_rsa.pub")}"
  }

  provisioner "file" {
    source      = "./Dockerfile"
    destination = "~/Dockerfile"
    connection {
      type     = "ssh"
      user     = "ubuntu"
      private_key = file("./id_rsa")
      host     = self.network_interface.0.nat_ip_address
    }
  }

  provisioner "file" {
    source      = "./key.json"
    destination = "~/key.json"
    connection {
      type     = "ssh"
      user     = "ubuntu"
      private_key = file("./id_rsa")
      host     = self.network_interface.0.nat_ip_address
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update && sudo apt install docker.io -y",
      "cat key.json | sudo docker login --username json_key --password-stdin cr.yandex",
      "sudo docker build -t cr.yandex/crp789tmi24lkfp3ieba/boxfuse .",
      "sudo docker push cr.yandex/crp789tmi24lkfp3ieba/boxfuse"
    ]
    connection {
      type     = "ssh"
      user     = "ubuntu"
      private_key = file("./id_rsa")
      host     = self.network_interface.0.nat_ip_address
    }
  }

  depends_on = [
    yandex_vpc_network.network-1,
  ]
}

resource "yandex_compute_instance" "vm-2" {
  name = "terraform2"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8vmcue7aajpmeo39kk"
      size = 20
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("./id_rsa.pub")}"
  }
  
  provisioner "file" {
    source      = "./key.json"
    destination = "~/key.json"
    connection {
      type     = "ssh"
      user     = "ubuntu"
      private_key = file("./id_rsa")
      host     = self.network_interface.0.nat_ip_address
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update && sudo apt install docker.io -y",
      "cat key.json | sudo docker login --username json_key --password-stdin cr.yandex",
      "sudo docker run -d -p 8080:8080 cr.yandex/crp789tmi24lkfp3ieba/boxfuse"
    ]
    connection {
      type     = "ssh"
      user     = "ubuntu"
      private_key = file("./id_rsa")
      host     = self.network_interface.0.nat_ip_address
    }
  }
  depends_on = [
    yandex_vpc_network.network-1,
  ]
}

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

# resource "docker_registry_image" "build_image" {
#   provider = docker.bulder
#   name = "cr.yandex/crp789tmi24lkfp3ieba/boxfuse"
#   build {
#     context = "."
#     remote_context = "https://github.com/viklosh/ds-ex14.git"
#     auth_config {
#       host_name = "cr.yandex"
#       user_name = "json_key"
#       password = file("./key.json")
#     }
#   }
# }