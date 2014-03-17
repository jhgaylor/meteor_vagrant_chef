This repositiory mirrors a blog post <link>.

For reference, here is the post.

I hope to shed some light on how to use [Vagrant](http://www.vagrantup.com/) and [chef-solo](http://docs.opscode.com/chef_solo.html) to automate the deployment of your [Meteor](http://meteor.com) app.


This is intended to be an interactive exercise in which you will follow along on your own computer.  In order to do so you will need to install [Meteor](http://meteor.com) and [Vagrant](http://www.vagrantup.com/).

By the end of this document you will have a working copy of the leaderboard app on a droplet, the term [Digital Ocean](https://www.digitalocean.com/) uses for a VM. For this example we will have a single droplet that serves the Meteor application via an [nginx](http://nginx.org/) proxy and runs [Mongodb](http://www.mongodb.org/). The goal is to leave you in a place that it will be within reach to expand your infrastructure.


According to its homepage, Vagrant is a tool to create and configure lightweight, reproducible, and portable development environments.  However, the power of Vagrant extends far beyond dev environments. It wouldn't hurt to do a bit of reading on the Vagrant site and verify that the getting started example works before continuing.


In Vagrant terms a [provider](http://docs.vagrantup.com/v2/providers/index.html) is used primarily to configure where the new virtual machines will be hosted. We will be using the [Digital Ocean provider](https://github.com/smdahlen/vagrant-digitalocean) in this tutorial.  Optionally you can install [VirtualBox]( https://www.virtualbox.org/). If you use VirtualBox as your provider, you will need to use a [different 'box'](http://www.vagrantbox.es/) because the Digital Ocean box is intended to load one of their images. You do not need to know how Virtualbox works to use it as a provider for Vagrant and you will disregard the `vm.provider` section below.


I have created a git repo to accompany this document. You can follow the code on [github](https://github.com/jhgaylor/meteor_vagrant_chef/).  There are commits for each step. (Please note that towards the end of the commit log I lost a fight with git and had to fix some bugs in the code.)


We start by creating our workspace and the leaderboard example app.  This will be the application we deploy.  Feel free to use your own app instead. It is critical that you will be able to successfully run `meteor bundle` later on whatever app you choose to use. [Results](https://github.com/jhgaylor/meteor_vagrant_chef/commit/1d4d725c727a8ace673fc69f77ea6b56a1868c3d)


```sh
$ mkdir -p ~/dev/meteor_vagrant_chef
$ cd ~/dev/meteor_vagrant_chef
$ meteor create --example leaderboard
```


Throughout this document I will preface code block with a filename.  The path of this file is relative to the root of the workspace we just created, `~/dev/meteor_vagrant_chef`


We now need to create a Vagrantfile. We will do this with the vagrant CLI. A [Vagrantfile](http://docs.vagrantup.com/v2/vagrantfile/index.html) is a configuration file for Vagrant. [Results](https://github.com/jhgaylor/meteor_vagrant_chef/commit/7fc7f2279a47f690ce257b66752c7bef086c7000)


```sh
$ vagrant init
```


The next step is to determine which [box](http://docs.vagrantup.com/v2/boxes.html) to use for your application. A box is a little like an image of a barebones OS. For the purposes of this example we will use the [Digital Ocean box](https://github.com/smdahlen/vagrant-digitalocean/raw/master/box/digital_ocean.box). 

Add the box information to the Vagrantfile. In the generated file we will delete line 13 and add the configuration required to have Vagrant use the correct box.


`Vagrantfile` [Results](https://github.com/jhgaylor/meteor_vagrant_chef/commit/eb43d381205e8a642aeba91bac2b2ce8b927d62b)


```ruby
config.vm.box = "digital_ocean"
config.vm.box_url = "https://github.com/smdahlen/vagrant-digitalocean/raw/master/box/digital_ocean.box"
```

Optional: To save some time later, you can go ahead and download the box using the vagrant CLI.

```sh
$ vagrant box add digital_ocean https://github.com/smdahlen/vagrant-digitalocean/raw/master/box/digital_ocean.box
```

If you have not already, create a [DigitalOcean](http://digitalocean.com) account, login, and [generate an API key](https://www.digitalocean.com/community/articles/how-to-use-the-digitalocean-api). Now install the Digital Ocean provider for Vagrant

```sh
$ vagrant plugin install vagrant-digitalocean
```

Configure Vagrant to create a Digital Ocean droplet for this VM. Vagrant's default provider is VirtualBox.

`Vagrantfile` [Results](https://github.com/jhgaylor/meteor_vagrant_chef/commit/fac2e3ec8e9d9a36655d78a129054e3179e3fbfc)


```ruby
config.vm.provider :digital_ocean do |provider|
  provider.client_id = "<DO_client_id>"
  provider.api_key = "<DO_api_key>"
  # discover other values on the create droplet page
  provider.image = "Ubuntu 12.04.3 x64"
  provider.region = "New York 2"
end
```

A requirement of the Digital Ocean provider is that we use ssh key authentication.

If you do not have a key you'd like to use already, [create a key pair](https://www.digitalocean.com/community/articles/how-to-use-ssh-keys-with-digitalocean-droplets).


```sh
$ ssh-keygen -t rsa
```

Follow the prompts on screen. Your new keys are probably located at `~/.ssh/id_rsa` and `~/.ssh/id_rsa.pub`


Within the `Vagrantfile` specify the location of the private key for the root account of the new droplet.


`Vagrantfile` [Results](https://github.com/jhgaylor/meteor_vagrant_chef/commit/d4b2ce688cea1e194bece7a1e99feb3025c13094)

```ruby
config.ssh.private_key_path = "~/.ssh/id_rsa"
```


Most of the initial Vagrantfile is commented example configurations and we can safely delete the irrelevant code from the Vagrantfile that was generated for us.  [View the commit](https://github.com/jhgaylor/meteor_vagrant_chef/commit/3d0e8bd9c2e98cb05b697cb316b249a0142bcaba)


We are done with our Vagrantfile for now and will move on to Chef.  It is outside of the scope of this document to delve into Chef's best practices. In order to keep things simple I will gloss over Chef features and I will use community cookbooks. Please keep in mind I am not a sys admin and there may be gaping, obvious security holes in the cookbook we are about to create.


Plugins are a way to add functionality to Vagrant. We need to install `vagrant-omnibus` and `vagrant-berkself`. `vagrant-omnibus` will ensure that your node is properly installed with Chef before attempting to provision and `vagrant-berkshelf` will manage your cookbooks and give you access to the community cookbooks.

```sh
$ vagrant plugin install vagrant-omnibus
$ vagrant plugin install vagrant-berkshelf
```

Next we need to create a Chef cookbook.  A cookbook is just a directory in which the directory structure is important and the existence of a few files is required.  You can replace 'leaderboard' with any name you like.[Results](https://github.com/jhgaylor/meteor_vagrant_chef/commit/8060cdb28c17bd6b037ee75d9314eb8361dfab93)

```sh
$ mkdir -p cookbooks/leaderboard/recipes
$ touch cookbooks/leaderboard/README.md
$ touch cookbooks/leaderboard/metadata.rb
$ touch cookbooks/leaderboard/recipes/default.rb
```


I'll leave the contents of `cookbooks/leaderboard/README.md` as an exercise for the reader.

Let's modify `cookbooks/leaderboard/metadata.rb` in order to tell chef a little about our cookbook. [Results](https://github.com/jhgaylor/meteor_vagrant_chef/commit/52049c2fcaa1f91c998b3f329465e66b0ddf2707)

```ruby
name                'leaderboard'
maintainer          '<you>'
maintainer_email    '<you@example.com>'
license             'MIT'
description         'Configures a meteor server'
long_description    IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version             '0.0.1'
```

Every cookbook has at least one recipe and it is called `default`.  We will use this recipe to install all the necessary software to run our meteor app in addition to installing the meteor app.  A typical cookbook would break these processes into multiple recipes.

`cookbooks/leaderboard/recipes/default.rb` [Results](https://github.com/jhgaylor/meteor_vagrant_chef/commit/e60e738e2ba07cb589c9ddec50ee8cd4e6191df2)

```ruby
# add some basics

# recipes run more chef code. these are from the community
include_recipe "apt"
include_recipe "sudo"
include_recipe "build-essential"

# install a webserver to proxy requests
include_recipe "nginx"

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
```

Using [attributes](http://docs.opscode.com/chef_overview_attributes.html) Chef allows us to define variables for use throughout recipes and templates. Like everything else in Chef, attributes are expected to be in their own folder within the cookbook.

```sh
$ mkdir cookbooks/leaderboard/attributes
$ touch cookbooks/leaderboard/attributes/default.rb
```


We didn't use any attributes in our recipe even though there are quite a few good ones to create. We do need to override some attributes from other cookbooks though.

Our attributes file configures sudoers, uses passwordless sudo, declares a specific nodejs version, instructs nginx to use upstart, and omits install meteorite.

`attributes/default.rb`

```rb
default['authorization']['sudo']['users'] = ['leader', 'vagrant']
default['authorization']['sudo']['passwordless'] = true
default.nodejs['version'] = '0.10.25'
default["nginx"]["init_style"] = "upstart"
# install meteor but don't install meteorite
node.default['meteor']['install_meteorite'] = false
```


Chef allows us to write template files in embedded ruby (.erb) and will fill in the variables from attributes in the cookbook. Our example app needs two templates.  One for nginx and the other for upstart. You can use templates to put any file on the target VM.


Templates are assumed to be in a folder `templates/<recipe>/` within a cookbook. Let's create our templates. [Results](https://github.com/jhgaylor/meteor_vagrant_chef/commit/b9417a86f489c08871aa7217f06221db1fd8d1df)


```sh
$ mkdir -p cookbooks/leaderboard/templates/default
$ touch cookbooks/leaderboard/templates/default/nginx.conf.erb
$ touch cookbooks/leaderboard/templates/default/leaderboard.upstart.conf
```

We will use a very basic nginx config file.  This will proxy requests received on port 80 to port 3000.


`cookbooks/leaderboard/templates/default/nginx.conf.erb`

```sh
server {
    location / {
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_ignore_client_abort off;
        proxy_buffering off;
        proxy_redirect off;
        proxy_pass   http://localhost:3000;
        proxy_read_timeout 60;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
    }
}
```

Our leaderboard upstart script will keep the meteor app running and log stdout/stderr to a file. This file assumes mongodb is available on the default port and that node is at `/usr/local/bin/node`.

`cookbooks/leaderboard/templates/default/leaderboard.upstart.conf.erb`

```sh
#!upstart
description "Leaderboard Upstart"
author "<you>"

env APP_NAME='leaderboard'
env PORT='3000'
env ROOT_URL="http://localhost"
env NODE_BIN='/usr/local/bin/node'
env MONGO_URL="mongodb://localhost:27017/meteor"

env SCRIPT_FILE="/home/leader/bundle/main.js"
env RUN_AS="leader"
start on (local-filesystems and net-device-up IFACE=eth0)
stop on shutdown

script
  export LOG_FILE="/home/leader/tracer.upstart.log"
  touch $LOG_FILE
  chown $RUN_AS:$RUN_AS $LOG_FILE
  chdir "/home/leader/"
  exec sudo -u $RUN_AS sh -c "PORT=$PORT MONGO_URL=$MONGO_URL ROOT_URL='$ROOT_URL' $NODE_BIN $SCRIPT_FILE >> $LOG_FILE 2>&1"
end script

respawn
respawn limit 20 30
```


Now that we have our template files we can tell Chef to include them on our new system. We accomplish that by using the [template resource](http://docs.opscode.com/resource_template.html) [Results](https://github.com/jhgaylor/meteor_vagrant_chef/commit/33e9664b341bff08853713ed3a2373bdef2a0e39)


`cookbooks/leaderboard/recipes/default.rb`

```ruby
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

# instruct the service to restart
service "leaderboard" do
  provider Chef::Provider::Service::Upstart
  action :restart
end
```


Let's create a new release of our meteor app using `meteor bundle`. [Results](https://github.com/jhgaylor/meteor_vagrant_chef/commit/bef447a93c084ba4c7a4c13a814b9ecc7e1017c3) 

```sh
$ cd leaderboard
$ meteor bundle ../bundle.tgz
$ cd ..
```


Ordinarily this would not be a good way to handle releases. This is a shortcut to keep the focus on Chef + Vagrant.


By default, Vagrant will rsync the folder containing the Vagrantfile with /vagrant on the new VM. 

In order to use the bundle, we have to instruct Chef to copy the tarball and unzip it where the upstart script expects it to be.  We also have to reinstall fibers via npm.  

Using a [bash resource](http://docs.opscode.com/chef/resources.html#bash) we can execute an arbitrary block of bash to do this job for us.

`cookbooks/leaderboard/default.rb` [Results](https://github.com/jhgaylor/meteor_vagrant_chef/commit/463916c5799e90f123c82f3451358a6af0384b8b)

```ruby
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
```


Using the cookbook metadata file we tell Chef which other cookbooks our `leaderboard` cookbook depends on.

`cookbooks/leaderboard/metadata.rb` [Results](https://github.com/jhgaylor/meteor_vagrant_chef/commit/cf667679d0e7797c01f1e0e012c47684a6b2f20a)

```ruby
supports "ubuntu"

depends "apt"
depends "nginx"
depends "meteor"
depends "sudo"

recipe  "leaderboard", "Installs the whole app stack"
```


To keep track of where to find our Chef dependancies we will use [Berkshelf](http://berkshelf.com/), which is similar to bundler for Chef cookbooks.  A Berksfile is the configuration file for Berkshelf.

```sh
$ touch ./Berksfile
```

Using the Berksfile we will identify cookbooks and where they can be found.  `site :opscode` tells Berkshelf that the cookbooks can be found on the [Opscode community site](http://community.opscode.com/cookbooks/).

`Berksfile` [Results](https://github.com/jhgaylor/meteor_vagrant_chef/commit/8fab0d0f891c413f28f27e92eb2b34fc6f88f052)

```ruby
cookbook "leaderboard", :path => "./cookbooks/leaderboard"

# instructs chef to grab these cookbooks from the community site.
site :opscode
cookbook "apt"
cookbook "nginx"
cookbook "meteor"
cookbook "sudo"
```


We have written all of the required Chef code and can now configure Vagrant to run the default recipe of our new cookbook.


In order to run `chef-solo` on the newly created VM, `chef-solo` needs to be installed.  By enabling the omnibus plugin you can be sure that the necessary chef provisioner is installed on all new VMs.


`Vagrantfile` [Results](https://github.com/jhgaylor/meteor_vagrant_chef/commit/aefcc93f5dc3dc4c44039680b2337c48fbc726a7)

```rb
config.omnibus.chef_version = :latest
```


For Chef to know where the necessary cookbooks are, we use [Berkshelf](http://berkshelf.com/). To use Berkshelf with the chef provisioner of Vagrant, enable the plugin.  [Results](https://github.com/jhgaylor/meteor_vagrant_chef/commit/65453a18c03173dcc9167bce5ce95c40da96905b)

```ruby
config.berkshelf.enabled = true
```


Finally configure Vagrant's provisioner to be chef-solo and to run our cookbook's default recipe. [Results](https://github.com/jhgaylor/meteor_vagrant_chef/commit/482ab69f87f979cc8b7b30d295dd663b3f821c97)

```ruby
config.vm.provision :chef_solo do |chef|
  chef.cookbooks_path = "cookbooks"
  chef.add_recipe "leaderboard"
end
```

Now `vagrant up` and visit your digital ocean control panel.  Once vagrant up is done you should see a new droplet.  Navigate your browser to the IP address of your new node to use the leaderboard.


More Reading:

http://www.vagrantup.com/

http://docs.opscode.com/

https://www.digitalocean.com/community/articles/how-to-use-digitalocean-as-your-provider-in-vagrant-on-an-ubuntu-12-10
