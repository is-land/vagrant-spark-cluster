# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.

require './vagrant/support_lib'

$nodes = read_nodes_definition
generateInventoryFile($nodes)
puts('=' * 60)

Vagrant.configure("2") do |config|
  config.ssh.insert_key = false
  config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"

  master_count = 0
  $nodes.each do |node|
    config.vm.define node['name'] do |cfg|
      cfg.vm.box = node['vm_box']
      cfg.vm.box_check_update = false
      cfg.vm.hostname = node['name']
      cfg.vm.network node['network']['identifier'], ip: node['network']['ip']
      cfg.vm.provider :virtualbox do |vb|
        vb.gui = false
        vb.memory = node['ram']
      end

      if (node['node_type']=='master') and (master_count==0)
        puts("Ansible control host: #{ node['name'] }")
        master_count = master_count + 1
        cfg.vm.provision 'shell', inline: $GENERATE_MASTER_SSHKEY
        cfg.vm.provision 'shell', inline: $INSTALL_ANSIBLE
      end
      cfg.vm.provision 'shell', inline: $APPEND_PUBLIC_KEY
    end
  end

end

master_sshkey = 'id_rsa.master'

$GENERATE_MASTER_SSHKEY = <<SCRIPT
  mkdir -p /home/vagrant/.ssh
  ssh-keygen -t rsa -N "" -f "/home/vagrant/.ssh/id_rsa" -C "vagrant@`hostname`"

  mkdir -p /vagrant/.ssh
  cp /home/vagrant/.ssh/id_rsa /vagrant/.ssh/#{master_sshkey}
  cp /home/vagrant/.ssh/id_rsa.pub /vagrant/.ssh/#{master_sshkey}.pub
  chown -R vagrant:vagrant /home/vagrant/.ssh
SCRIPT

$INSTALL_ANSIBLE = <<SCRIPT
  apt-get -y install software-properties-common
  apt-add-repository ppa:ansible/ansible
  apt-get -y update
  apt-get -y install ansible
SCRIPT

$APPEND_PUBLIC_KEY = <<SCRIPT
  cat /vagrant/.ssh/#{master_sshkey}.pub >> /root/.ssh/authorized_keys
  cat /vagrant/.ssh/#{master_sshkey}.pub >> /home/vagrant/.ssh/authorized_keys
SCRIPT
