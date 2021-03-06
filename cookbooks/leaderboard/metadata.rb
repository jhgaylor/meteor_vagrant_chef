name                'leaderboard'
maintainer          '<you>'
maintainer_email    '<you@example.com>'
license             'MIT'
description         'Configures a meteor server'
long_description    IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version             '0.0.1'

supports "ubuntu"

depends "apt"
depends "nginx"
depends "meteor"
depends "sudo"

recipe  "leaderboard", "Installs the whole app stack"