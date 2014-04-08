# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

	testMDB1ip = "10.8.1.5"
	testMDB2ip = "10.8.1.6"

	hostsfile_attrs = [
		{
			"ip" => testMDB1ip,
			"host" => "testMDB1"
		},
		{
			"ip" => testMDB2ip,
			"host" => "testMDB2"
		}
	]

	config.vm.define "master" do |config|

		config.vm.box = "debian6"
		config.vm.hostname = "testMDB1"
		config.vm.box_url = "http://apt.drweb.com/debian/squeeze_x64.box"

		config.vm.network "private_network", ip: testMDB1ip

		config.vm.provision :chef_solo do |chef|

			chef.cookbooks_path = "cookbooks"
			chef.data_bags_path = "data_bags"
			chef.roles_path = "roles"

			chef.node_name = config.vm.hostname

			chef.add_role "mongodb_replicaset"

			chef.json = {
				"hostsfile-attrs" => hostsfile_attrs
			}
		end
	end

	config.vm.define "slave" do |config|

		config.vm.box = "debian6"
		config.vm.hostname = "testMDB2"
		config.vm.box_url = "http://apt.drweb.com/debian/squeeze_x64.box"

		config.vm.network "private_network", ip: testMDB2ip

		config.vm.provision :chef_solo do |chef|

			chef.cookbooks_path = "cookbooks"
			chef.data_bags_path = "data_bags"
			chef.roles_path = "roles"

			chef.node_name = config.vm.hostname

			chef.add_role "mongodb_replicaset"

			chef.json = {
				"hostsfile-attrs" => hostsfile_attrs
			}
		end
	end

end

