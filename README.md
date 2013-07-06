# Dedicate Redis services for Cloud Foundry

TODO: Write a gem description

## Requirements

It is assumed that you have access to the same bosh being used to deploy your Cloud Foundry.

Confirm this by running:

```
$ bosh status
$ bosh deployments
```

The former will confirm you are targeting a bosh. The latter will display the deployments. One of which should be your Cloud Foundry.

This requirement exists so as to share the same DNS between the redis deployments and the Cloud Foundry deployment.

## Installation

Install via RubyGems:

```
$ gem install redis-cf-plugin
```

## Usage

Each time you install the latest `redis-cf-plugin` you will want to re-upload the latest available redis release to your bosh. If no newer release is available then nothing good nor bad will occur.

```
$ cf prepare-redis
Uploading new redis release to bosh...
```

To create/provision a new redis service you run the following command. By default, it will select the smallest known instance size.

```
$ cf create-redis myapp-redis
$ cf create-redis myapp-redis --size small
$ cf create-redis myapp-redis --size medium
$ cf create-redis myapp-redis --size large
$ cf create-redis myapp-redis --size xlarge
```

To see the list of available instance sizes or to edit the list of available instance size, see the section "Customizing" below.

To bind the redis service to an existing Cloud Foundry application (regardless if its running or not) via a simple URI passed as an environment variable, you run the following command. By default, the environment variable is `$REDIS_URI`.

```
$ cf bind-redis-env-var myapp-redis myapp
$ cf bind-redis-env-var myapp-redis myapp --env-var REDISTOGO
```

Currently there is no way to load the redis service into Cloud Foundry as a "provisioned service instance". This will be implemented soon (in association with the Service Connector API).

## Customizing

TODO - how to show available instance sizes
TODO - how to edit available instance sizes (via the bosh deployment file templates)

## Releasing new plugin gem versions

There are three reasons to release new versions of this plugin.

1. Package the latest [redis-boshrelease](https://github.com/cloudfoundry-community/redis-boshrelease) bosh release (which describes how the redis service is implemented)
2. New features or bug fixes to the plugin
3. Fix regressions caused by newer versions of the `cf` CLI or newer Cloud Foundry releases

To package the latest "final release" of the redis bosh release into this source repository, run the following command:

```
$ cd /path/to/releases
$ git clone https://github.com/cloudfoundry-community/redis-boshrelease.git
$ cd -
$ rake bosh:release:import[/path/to/releases/redis-boshrelease]
# for zsh shell quotes are required around rake arguments:
$ rake bosh:release:import'[/path/to/releases/redis-boshrelease]'
```

Note: only the latest "final release" will be packaged. See https://github.com/cloudfoundry-community/redis-boshrelease#readme for information on creating new bosh releases.

To install and test the plugin:

```
$ rake install
$ cf
```

To release a new version of the plugin as a RubyGem:

1. Edit `redis-cf-plugin.gemspec` to update the major or minor or patch version.
2. Run the release command:

```
$ rake release
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
