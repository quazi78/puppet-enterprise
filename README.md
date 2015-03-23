# Vagrant-based Puppet-Enterprise Split Installation

This project is used for creating a small monolithic installation of Puppet Enterprise for testing and evaluation purposes. It is not suitable for production use. The Puppet Master, PuppetDB, Console, and Certificate Authority are all installed on the same server. Nodes (Enterprise Linux and Windows) to be managed with Puppet are also provisioned to comprise a complete testing environment.

For a split (each service on its own VM) Puppet Enterprise version of this project try [split-puppet-enterprise](https://github.com/singlestone/split-puppet-enterprise).


## Requirements

You must have:
- [Vagrant](https://www.vagrantup.com)
- [VirtualBox](https://www.virtualbox.org)
- Sufficient RAM to run the VMs. By default, the VMs are configured with 7.25 GiB (total) of RAM. Having at least 10 GiB of RAM installed in your host machine is advisable to avoid swapping. You can adjust the VM RAM settings in the Vagrantfile, however some Puppet components may not perform adequately with lower amounts.
- A [Zeroconf](https://en.wikipedia.org/wiki/Zero-configuration_networking)/[Bonjour](https://en.wikipedia.org/wiki/Bonjour_(software)) client running on your host machine (i.e. your laptop). Any Mac running OS X already has this. For Windows, try Apple's [Bonjour Print Services](https://support.apple.com/kb/DL999?locale=en_US), which installs the required components. You can also install Bonjour (64-bit) from the binary repository referenced in the Vagrantfile. On Linux, install Avahi/mDNS.

The Vagrantfile supports the [`vagrant-cachier`](https://github.com/fgrehm/vagrant-cachier) plugin to cache yum repositories for faster startup. It is not required but can considerably reduce  ```vagrant up``` times during subsequent runs by caching RPMs from ```yum``` operations.


## How to Use

Clone this repository, and ```cd``` to the repo directory. Then run ```vagrant up``` to get started. At the beginning of the first run the required binaries (Puppet Enterprise installer, Puppet Enterprise Agent for Windows, and Bonjour client for Windows) will be downloaded. Once the VMs have launched, you can run ```vagrant ssh``` to connect to the Puppet Master. To access the Puppet Enterprise Console, point your browser to https://puppet.local. The username is `admin` and the password is `puppetpassword`. (The password can be changed in the `puppet.answer` file in this repository.)


## Troubleshooting & Known Issues

Here are some common problems you may encounter:

### I get errors whenever I provision a Windows node

This stems from a known issue in Vagrant 1.7.2 that should be resolved in 1.7.3. The problem is that Vagrant no longer reboots Windows nodes after their hostname is changed (via ```winnode.vm.hostname = "win-node#{i}.#{DOMAIN}"```) even though a reboot is required. As a result, the Puppet Enterprise agent fails to install. As a workaround:

1. Run ```vagrant up``` as you normally would to start the entire stack. You will see errors during the Windows node provisioning stage.
2. Run ```vagrant halt win-node0```
3. Run ```vagrant up win-node0```.
4. Run ```vagrant provision win-node0```. During this re-provisioning phase the Puppet Enterprise agent should be successfully installed.
5. Repeat the above steps for any other Windows nodes you have.

For more information on the Vagrant bug (and fix) see https://github.com/mitchellh/vagrant/pull/5261.

### My computer slows to a crawl when I run ```vagrant up```!

Your computer probably doesn't have enough memory to run all of the VMs concurrently. Try adjusting the RAM settings in the Vagrantfile. The parameter names all start with "```MEMORY_```" followed by the role of the VM. You may adjust the number of virtual CPU cores each VM gets with the "```CPU_```" parameters. You can also reduce the number of managed nodes with the ```EL_INSTANCES``` (Linux) and ```WIN_INSTANCES``` (Windows) parameters.

### I see `Error: Cannot retrieve metalink for repository: epel. Please verify its path and try again` scroll by during provisioning

There is a sporadic problem with connecting to the [EPEL](https://fedoraproject.org/wiki/EPEL) yum repository. The indication that there is an issue will appear in the Vagrant output while running ```vagrant up```:

```
==> puppet: Installed:
==> puppet:   epel-release.noarch 0:6-8                                                     
==> puppet: Complete!
==> puppet: Loaded plugins: fastestmirror
==> puppet: Setting up Install Process
==> puppet: Loading mirror speeds from cached hostfile
==> puppet: Error: Cannot retrieve metalink for repository: epel. Please verify its path and try again
==> puppet: atd: unrecognized service
==> puppet: messagebus: unrecognized service
==> puppet: avahi-daemon: unrecognized service
```

If the EPEL repo is unavailable, then required packages will not be installed, causing the subsequent Puppet Enterprise installation to fail.

The cause of this problem is unclear, but it could be caused by incorrect time settings on the VM or certificate problems with certain EPEL mirrors when connecting. The best workaround at this time is to destroy the VM (i.e. ```vagrant destroy --force puppet```) and then re-run ```vagrant up```.


## Future Enhancements

- Add option to provision to AWS instead of VirtualBox.