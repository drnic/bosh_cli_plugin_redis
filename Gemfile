source 'https://rubygems.org'
source 'https://s3.amazonaws.com/bosh-jenkins-gems/' # for prerelease bosh_cli

# Specify your gem's dependencies in redis-cf-plugin.gemspec
gemspec

bosh_cli_path = File.expand_path("~/gems/cloudfoundry/bosh/bosh_cli")
if File.directory?(bosh_cli_path)
  gem "bosh_cli", path: bosh_cli_path
end