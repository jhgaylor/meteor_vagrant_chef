# add some basics

# recipes run more chef code. these are from the community
include_recipe "apt"
include_recipe "sudo"
include_recipe "build-essential"

# install a webserver to proxy requests
include_recipe "nginx"

# install meteor but don't install meteorite
node.default['meteor']['install_meteorite'] = false
include_recipe "meteor"

# packages use the platform package system
# apt-get install curl
package "curl"
package "git"

# add a user
user "leader" do
  system true
  home "/home/leader"
  supports :manage_home => true
  shell "/bin/bash"
end