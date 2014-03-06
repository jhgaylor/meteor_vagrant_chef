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

# uses an attribute of the nginx cookbook
template "#{node.default['nginx']['dir']}/sites-available/default" do
  source "nginx.conf.erb"
  mode 0777
  owner node.default['nginx']['user']
  group node.default['nginx']['user']
end

template "/etc/init/leaderboard.conf" do
  source "leaderboard.upstart.conf.erb"
  mode 0777
  owner "root"
  group "root"
end

bash "build_app" do
  cwd "/vagrant"
  user "leader"
  group "leader"
  code <<-EOH
    if [ -d "bundle" ]; then
      rm -rf bundle
    fi
    tar -zxvf bundle.tgz
    mv -rf bundle /home/leader
    cd /home/leader/bundle/programs/server
    sudo npm uninstall fibers
    sudo npm install fibers
    EOH
end

# instruct the service to restart
service "leaderboard" do
  provider Chef::Provider::Service::Upstart
  action :restart
end