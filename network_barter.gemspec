# Gem metadata.
#
# How to bundle this as a gem, install it locally for client apps, and publish it to rubygems.org:
#   gem build network_barter.gemspec
#   gem install ./network_barter-0.1.0.gem
#   gem push network_barter-0.1.0.gem
#
# File format reference: http://guides.rubygems.org/specification-reference/
#
# @todo Add depedency information.
Gem::Specification.new do |spec|
  # Essential metadata for gem system.
  spec.name        = 'network_barter'
  spec.version     = '0.1.0.pre1'
  spec.date        = '2013-07-11'
  spec.summary     = 'Library providing various implementations of the network barter algorithm.'

  # Contact metadata.
  spec.authors     = ['Daniel Ansorg', 'Matthias Ansorg']
  spec.email       = 'matthias@ansorgs.de'
  spec.homepage    = 'http://edgeryders.eu/economy-app'
  spec.metadata = {
      'Bug Tracker' => 'https://github.com/makerfoxnet/network_barter/issues',
      'Source Code' => 'https://github.com/makerfoxnet/network_barter'
  }

  # Description.
  spec.description = <<-EOF
    A library that implements the network barter algorithm, which means multi-party bartering in general graph
    shapes, not just in circular shape.
  EOF

  # File related.
  spec.files       = ["lib/network_barter.rb"]
  spec.require_path = '.'
  spec.require_paths << 'lib'
end
