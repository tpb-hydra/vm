Vagrant.configure("2") do |config|
  config.vm.box = "squeeze32"
  config.vm.box_url = "http://mathie-vagrant-boxes.s3.amazonaws.com/debian_squeeze_32.box"

  config.vm.network :forwarded_port, guest: 80, host: 1337
  config.ssh.forward_agent = true

  config.vm.provider :virtualbox do |v|
    v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    v.customize ["modifyvm", :id, "--memory", 512]
    v.customize ["modifyvm", :id, "--name", "tpb"]
  end

  config.vm.synced_folder "./share/", "/vagrant/", id: "vagrant-root" 
  config.vm.provision :shell, :inline => "sudo apt-get update"

  config.vm.provision :puppet do |puppet|
    puppet.manifests_path = "manifests"
    puppet.module_path = "modules"
    puppet.options = ['--verbose']
  end
end
