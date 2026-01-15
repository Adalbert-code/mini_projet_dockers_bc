# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  config.vm.define "dockerPayMyBuddy" do |dockerPayMyBuddy|
    dockerPayMyBuddy.vm.box = "eazytrainingfr/ubuntu"
    dockerPayMyBuddy.vm.box_version = "1.0"
    # dockerPayMyBuddy.vm.network "private_network", type: "dhcp"
    dockerPayMyBuddy.vm.network "private_network", type: "static", ip: "192.168.56.5"
    dockerPayMyBuddy.vm.hostname = "dockerPayMyBuddy"
    dockerPayMyBuddy.vm.provider "virtualbox" do |v|
      v.name = "dockerPayMyBuddy"
      v.memory = 8192
      v.cpus = 4
    end
    dockerPayMyBuddy.vm.provision :shell do |shell|
      shell.path = "install_docker.sh"
      shell.env = { 'ENABLE_ZSH' => ENV['ENABLE_ZSH'] }
    end
  end
end