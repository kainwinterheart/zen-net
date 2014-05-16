# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

    testMDB1ip = "10.8.1.5"

    hostsfile_attrs = [
        {
            "ip" => testMDB1ip,
            "host" => "testMDB1"
        }
    ]

    config.vm.define "master" do |config|

        config.vm.box = "debian7"
        config.vm.hostname = "testMDB1"
        config.vm.box_url = "http://127.0.0.1/~gennadiy/debian-7-4-0.box"

        config.vm.network "private_network", ip: testMDB1ip

        config.vm.provision :chef_solo do |chef|

            chef.cookbooks_path = "cookbooks"
            chef.data_bags_path = "data_bags"
            chef.roles_path = "roles"

            chef.node_name = config.vm.hostname

            chef.add_role "common"
            chef.add_role "mongodb"
            chef.add_role "perl"

            chef.add_recipe "nginx-simple"

            chef.json = {
                "hostsfile-attrs" => hostsfile_attrs
            }
        end
    end

end
