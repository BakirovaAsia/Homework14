terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  token     = "AgAAAABRl1XhAATuwYX5S9lFNkmml4SmcfTlwh8"
  cloud_id  = "b1gaukp5b6t786s5v82q"
  folder_id = "b1g8vakc2uotg05v3orc"
  zone      = "ru-central1-c"
}

resource "yandex_compute_instance" "vm-1" {
  name = "build-vm"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd81d2d9ifd50gmvc03g"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }

}

resource "yandex_compute_instance" "vm-2" {
  name = "deploy-vm"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd81d2d9ifd50gmvc03g"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }

}

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-c"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource yandex_container_registry "my-registry" {
  folder_id = "b1g8vakc2uotg05v3orc"
  name      = "docker-registry"
}

resource yandex_container_repository repo-1 {
  name      = "${yandex_container_registry.my-registry.id}/repo-1"
}

resource "yandex_container_repository_iam_binding" "puller" {
  repository_id = yandex_container_repository.repo-1.id
  role        = "container-registry.images.puller"

  members = [
    "system:allUsers",
  ]
}

resource "yandex_container_repository_iam_binding" "pusher" {
  repository_id = yandex_container_repository.repo-1.id
  role        = "container-registry.images.pusher"

  members = [
    "serviceAccount:${yandex_iam_service_account.sa.id}",
  ]
}

resource "yandex_iam_service_account" "sa" {
  name        = "vmmanager"
  description = "service account to manage VMs"
  folder_id = "b1g8vakc2uotg05v3orc"
}

output "internal_ip_address_vm_1" {
  value = yandex_compute_instance.vm-1.network_interface.0.ip_address
}

output "internal_ip_address_vm_2" {
  value = yandex_compute_instance.vm-2.network_interface.0.ip_address
}

resource "null_resource" "web" {
  # ...

  provisioner "local-exec" {
    command = "echo vm1: ${yandex_compute_instance.vm-1.network_interface.0.ip_address}"
  }
}


