# Gem metadata.
#
# To update this gem in client apps using it from its git source:
#   cd <network_barter gitroot>
#   git push
#   cd <client app gitroot>
#   bundle update network_barter
#
# To bundle this gem in client apps using it from its (not yet existing) RubyGems source:
#   cd <network_barter gitroot>
#   gem build network_barter.gemspec
#   gem push network_barter-0.1.0.gem
#   cd <client app gitroot>
#   bundle update network_barter
#
# File format reference: http://guides.rubygems.org/specification-reference/
#
# @todo Add depedency information.
# @todo Add dependency for neography (https://github.com/maxdemarzi/neography/).
Gem::Specification.new do |spec|
  # Essential metadata for gem system.
  spec.name        = 'network_barter'
  # spec.rubyforge_project     = spec.name # @todo Enable once on RubyForge.
  spec.version     = '0.1.0.pre2'
  spec.date        = '2013-07-11'
  spec.summary     = 'Library providing various implementations of the network barter algorithm.'

  # Contact metadata.
  spec.authors     = ['Daniel Ansorg', 'Matthias Ansorg']
  spec.email       = 'matthias@ansorgs.de'
  spec.homepage    = 'http://edgeryders.eu/economy-app'
  # @todo Re-enable once RubyGems >=1.9.0 is available on Heroku.
  # spec.required_rubygems_version = ">= 1.9.0" # Due to using spec.metadata.
  # spec.metadata = {
  #     'Bug Tracker' => 'https://github.com/makerfoxnet/network_barter/issues',
  #     'Source Code' => 'https://github.com/makerfoxnet/network_barter'
  # }

  # Description.
  spec.description = <<-EOF
    A library that implements the network barter algorithm, which means multi-party bartering in general graph
    shapes, not just in circular shape.
  EOF

  # Requirements.
  spec.files       = ["lib/network_barter.rb"]
  spec.require_path = '.'
  spec.require_paths << 'lib'
end
