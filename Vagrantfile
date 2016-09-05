# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.

require './vagrant/support_lib'

puts('=' * 60)
$nodes = readNodesDefinition
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

master_sshkey = 'id_rsa.vagrant'

$GENERATE_MASTER_SSHKEY = <<SCRIPT
  mkdir -p /vagrant/.ssh
  ssh-keygen -t rsa -N "" -f "/vagrant/.ssh/#{master_sshkey}" -C "vagrant@`hostname`"

  mkdir -p /home/vagrant/.ssh
  cp /vagrant/.ssh/#{master_sshkey} /home/vagrant/.ssh/id_rsa
  cp /vagrant/.ssh/#{master_sshkey}.pub /home/vagrant/.ssh/id_rsa.pub
  chown vagrant:vagrant /home/vagrant/.ssh/id_rsa*
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
