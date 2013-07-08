source 'https://rubygems.org'
source 'https://s3.amazonaws.com/bosh-jenkins-gems/' # for prerelease bosh_cli

# Specify your gem's dependencies in redis-cf-plugin.gemspec
gemspec

if File.directory?("~/gems/cloudfoundry/bosh/bosh_cli")
  gem "bosh_cli", path: "~/gems/cloudfoundry/bosh/bosh_cli"
end