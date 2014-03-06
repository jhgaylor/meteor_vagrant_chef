node.default['authorization']['sudo']['users'] = ['leader', 'vagrant']
node.default['authorization']['sudo']['passwordless'] = true

# install meteor but don't install meteorite
node.default['meteor']['install_meteorite'] = false

default["nginx"]["init_style"] = "upstart"

default.nodejs['version'] = '0.10.25'