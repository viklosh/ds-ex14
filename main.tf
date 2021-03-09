terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
      version = "0.51.1"
    }
  }
}

provider "yandex" {
  service_account_key_file = "./key.json"
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = "ru-central1-a"
}

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

  provisioner "local-exec" {
    command = "ansible-playbook ansible-build.yaml -e 'hostname=${self.network_interface.0.nat_ip_address}'"
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

  provisioner "local-exec" {
    command = "ansible-playbook ansible-deploy.yaml -e 'hostname=${self.network_interface.0.nat_ip_address}'"
  }

  depends_on = [
    yandex_vpc_network.network-1,
    yandex_compute_instance.vm-1,
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
