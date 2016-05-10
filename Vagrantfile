# -*- mode: ruby -*-
# vi: set ft=ruby :

PUPPET_ENTERPRISE_VERSION="3.8.1"

URL="https://s3.amazonaws.com/ddig-puppet"
PE_INSTALLER="puppet-enterprise-#{PUPPET_ENTERPRISE_VERSION}-el-6-x86_64.tar.gz"
PE_WIN_AGENT="puppet-enterprise-#{PUPPET_ENTERPRISE_VERSION}-x64.msi"
BONJOUR_WIN_CLIENT="Bonjour64.msi"

EL_BOX="puppetlabs/centos-6.6-64-nocm"
WIN_BOX="chrisbelyea/windows2012r2core"

# Check for required installers and download if missing
if ! File.exists?('./bin')
  printf "The 'bin' directory was not found, creating it..."
  require 'fileutils'
  FileUtils.mkdir_p './bin'
  puts "done."
end

if ! File.exists?("./bin/#{PE_INSTALLER}")
  puts "\033[31mPuppet Enterprise installer could not be found!\033[39m."
  printf "Downloading #{URL}/#{PE_INSTALLER} (be patient!)..."
  #puts "Please run '\033[36m./run_first.sh\033[39m' to download required dependencies."
  require 'open-uri'
  open("./bin/#{PE_INSTALLER}", "wb") do |file|
    file << open("#{URL}/#{PE_INSTALLER}", "rb").read
  end
  puts "done."
  #exit 1
end

if ! File.exists?("./bin/#{PE_WIN_AGENT}")
  puts "\033[31mPuppet Enterprise Windows agent installer could not be found!\033[39m."
  printf "Downloading #{URL}/#{PE_WIN_AGENT} (be patient!)..."
  #puts "Please run '\033[36m./run_first.sh\033[39m' to download required dependencies."
  require 'open-uri'
  open("./bin/#{PE_WIN_AGENT}", "wb") do |file|
    file << open("#{URL}/#{PE_WIN_AGENT}", "rb").read
  end
  puts "done."
  #exit 1
end

if ! File.exists?("./bin/#{BONJOUR_WIN_CLIENT}")
  puts "\033[31mBonjour installer could not be found!\033[39m."
  printf "Downloading #{URL}/#{BONJOUR_WIN_CLIENT} (be patient!)..."
  #puts "Please run '\033[36m./run_first.sh\033[39m' to download required dependencies."
  require 'open-uri'
  open("./bin/#{BONJOUR_WIN_CLIENT}", "wb") do |file|
    file << open("#{URL}/#{BONJOUR_WIN_CLIENT}", "rb").read
  end
  puts "done."
  #exit 1
end

# Puppet Enterprise Installer
PE_VERSION="puppet-enterprise-#{PUPPET_ENTERPRISE_VERSION}-el-6-x86_64"
PE_BUNDLE="./bin/#{PE_VERSION}.tar.gz"

# Hostnames of systems
NAME_PUPPET="puppet"
NAME_NODE="node"

# Group name (used in VirtualBox GUI)
GROUP="Puppet Enterprise"

# Managed nodes. The total cannot be greater than seven because of PE licensing.
# Number of Enterprise Linux managed nodes to create.
EL_INSTANCES=1

# Number of Windows 2012 
WIN_INSTANCES=1

# Domain for all nodes, i.e. "example.com". Defaults to "local" for support with
# Zeroconf (Avahi)/Bonjour. If you change this, ensure that a reliable DNS source
# is available and configured.
# Changing this requires modifying the answer files.
DOMAIN="local"

# CPU settings for Puppet infrastructure and managed nodes
CPU_PUPPET=2
CPU_NODE=1

# Memory settings for Puppet infrastructure and managed nodes
MEMORY_PUPPET=4096
MEMORY_NODE=384

# Puppet configuration parameters
RUNINTERVAL="5m"
ENVIRONMENT_TIMEOUT="30s"

# Pause after Avahi startup
AVAHI_DELAY="10"


Vagrant.configure("2") do |config|
  config.vm.define NAME_PUPPET, primary: true do |puppet|
    puppet.vm.box = EL_BOX
    if Vagrant.has_plugin?("vagrant-cachier")
      config.cache.scope = :box
    end
    puppet.vm.hostname = "#{NAME_PUPPET}.#{DOMAIN}"
    puppet.vm.network "private_network", type: "dhcp"
    puppet.vm.provider "virtualbox" do |v|
      v.name = "Puppet"
      v.memory = MEMORY_PUPPET
      v.cpus = CPU_PUPPET
      v.customize [ 
        "modifyvm", :id,
        "--groups", "/#{GROUP}",
        "--ioapic", "on"
      ]
    end
    puppet.vm.provision "shell", inline: <<-SHELL
      yum upgrade --assumeyes ca-certificates
      yum install --assumeyes epel-release
      yum install --assumeyes avahi avahi-compat-libdns_sd nss-mdns at
      service atd start
      service iptables stop
      service messagebus restart
      service avahi-daemon restart
      sleep #{AVAHI_DELAY} # wait for avahi-daemon to discover other servers
      tar --extract --ungzip --file=/vagrant/#{PE_BUNDLE} -C /tmp/
      /tmp/#{PE_VERSION}/puppet-enterprise-installer -A /vagrant/#{NAME_PUPPET}.answer
      echo -e "autosign = true\n" >> /etc/puppetlabs/puppet/puppet.conf
      /usr/local/bin/puppet config set environment_timeout #{ENVIRONMENT_TIMEOUT} --section master
      /usr/local/bin/puppet config set runinterval #{RUNINTERVAL} --section agent
      service pe-puppetserver restart
      service pe-puppet restart
      echo -e "<?xml version=\"1.0\" standalone='no'?><\!--*-nxml-*-->\n<\!DOCTYPE service-group SYSTEM "avahi-service.dtd">\n\n<service-group>\n\n\t<name replace-wildcards=\"yes\">Puppet Enterprise Console (%h)</name>\n\n\t<service>\n\t\t<type>_https._tcp</type>\n\t\t<port>443</port>\n\t</service>\n\n</service-group>\n" >> /etc/avahi/services/pe-console.service
    SHELL
    puppet.vm.post_up_message = "Puppet Enterprise is now running. Access the console at '\033[36mhttps://#{NAME_PUPPET}.#{DOMAIN}\033[32m'. The username is '\033[34madmin\033[32m' and the password is '\033[34mpuppetpassword\033[32m'."
  end

  EL_INSTANCES.times do |i|
    config.vm.define "el-node#{i}".to_sym do |elnode|
      elnode.vm.box = EL_BOX
      if Vagrant.has_plugin?("vagrant-cachier")
        config.cache.scope = :machine
      end
      elnode.vm.hostname = "el-node#{i}.#{DOMAIN}"
      elnode.vm.network "private_network", type: "dhcp"
      elnode.vm.provider "virtualbox" do |v|
        v.name = "PE-Managed EL Node #{i}"
        v.memory = MEMORY_NODE
        v.cpus = CPU_NODE
        v.customize [
          "modifyvm", :id,
          "--groups", "/#{GROUP}",
          "--ioapic", "on"
        ]
      end
      elnode.vm.provision "shell", inline: <<-SHELL
      yum upgrade --assumeyes ca-certificates
      yum install --assumeyes epel-release
      yum install --assumeyes avahi avahi-compat-libdns_sd nss-mdns
      service iptables stop
      service messagebus restart
      service avahi-daemon restart
      sleep #{AVAHI_DELAY} # wait for avahi-daemon to discover other servers
      curl -k https://puppet.local:8140/packages/current/install.bash | sudo bash
      /usr/local/bin/puppet config set environment_timeout #{ENVIRONMENT_TIMEOUT} --section master
      /usr/local/bin/puppet config set runinterval #{RUNINTERVAL} --section agent
      service pe-puppet restart
      SHELL
    end
  end
  
  WIN_INSTANCES.times do |i|
    config.vm.define "win-node#{i}".to_sym do |winnode|
      winnode.vm.guest = :windows
      winnode.vm.communicator = "winrm"
      winnode.winrm.timeout = 500
      winnode.vm.box = WIN_BOX
      winnode.vm.hostname = "win-node#{i}"
      winnode.vm.network "private_network", type: "dhcp"
      winnode.vm.network :forwarded_port, guest: 5985, host: 5985, id: "winrm", auto_correct: true
      winnode.vm.network :forwarded_port, guest: 3389, host: 3389, id: "rdp", auto_correct: true
      winnode.vm.provider "virtualbox" do |v|
        v.name = "PE-Managed Windows Node #{i}"
        v.memory = MEMORY_NODE
        v.cpus = CPU_NODE
        v.customize [
          "modifyvm", :id,
          "--groups", "/#{GROUP}"
        ]
      end
      #winnode.vm.provision :shell, inline: "Restart-Computer"
      winnode.vm.provision :shell, path: "./scripts/Install-BonjourClient.ps1"
      winnode.vm.provision "shell" do |s|
        s.path = "./scripts/Install-PuppetEnterpriseAgent.ps1"
        s.args = ["#{NAME_PUPPET}", "#{PE_WIN_AGENT}"]
      end
    end
  end

end
