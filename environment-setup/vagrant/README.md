# Virtual Machine Testing Environment

## Vagrant

Vagrant is a tool for building and managing virtual machine environments
in a single workflow.  With an easy-to-use workflow and focus on
automation.

* `vagrant up`: Starts all machines in Vagrantfile.
* `vagrant halt`: Shutdown all machines in Vagrantfile.
* `vagrant destroy [name]`: Destroy the referenced virtual machine.
* `vagrant status`: Show information on all virtual machines.

Note: We set `ENV['VAGRANT_NO_PARALLEL'] = 'yes'` to start machines
sequentially, taking into account dependencies. We can use `vagrant up
--no-parallel` instead.

To execute these commands, it is necessary to be in the folder of the
Vagrantfile file.  After using the VMs, remember to destroy them
(`vagrant destroy`) to free up (RAM)disk space.

## Installation

``` {bash}
sudo apt install libvirt-clients libvirt-daemon-system libvirt0 vagrant
```

To use `libvirt`, you may need to add your user to the `libvirt` group:

``` {bash}
sudo usermod -aG libvirt <user>
```

### Configuration

* Users must be in `libvirt` group to run Vagrant without `sudo`.
* When using on a server, forward your Git SSH key with using an SSH
  agent so you can access GitHub remotely using SSH.
* Check write permissions on `known_hosts`.
* If you have Ansible installed on your machine, the use of a virtual
  environment is encouraged to use a more recent, tested version of
  Ansible (see below).

### Notes

* We have a lot more info on Vagrant for [PEERING][peering-vm-tests-vagrant]

[peering-vm-tests-vagrant]: https://github.com/PEERINGTestbed/server/tree/master/vm-tests