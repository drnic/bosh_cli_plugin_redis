# Dedicate Redis services on AWS or OpenStack

This is a simple `bosh` CLI plugin to create and delete dedicated redis services and provide a simple URI. It runs on AWS or OpenStack via bosh.

Example create/delete scenario that includes binding the redis service to a Cloud Foundry application via environment variables:

```
$ bosh prepare redis
$ bosh create redis
$ bosh show redis uri
redis://:c1da049a75b3@0.redis.default.demoredis.microbosh:6379/0
$ cf set-env myapp REDIS_URI redis://:c1da049a75b3@0.redis.default.redis-123.microbosh:6379/0

$ cf unset-env myapp REDIS_URI
$ bosh delete redis
```

The resulting redis servers can be discovered and accessed by any systems (such as Cloud Foundry applications) using the same bosh (or microbosh) or a connected DNS.

## Why not use Cloud Foundry v2 services?

See [discussion](https://groups.google.com/a/cloudfoundry.org/d/msg/bosh-users/yoXGZMcWduc/8xocVYxpKakJ) on vcap-dev mailing list. 

## Requirements

You must use the same BOSH for deploying redis as you use to deploy Cloud Foundry (unless your DNS is configured to be shared across the two BOSH).

It is also requried that you have login access to the same BOSH being used to deploy your Cloud Foundry.

Confirm this by running:

```
$ bosh status
$ bosh deployments
```

The former will confirm you are targeting a bosh. The latter will display the deployments. One of which should be your Cloud Foundry.

## Installation

Install via RubyGems:

```
$ gem install bosh_cli "~> 1.5.0.pre" --source https://s3.amazonaws.com/bosh-jenkins-gems/ 
$ gem install bosh_cli_plugin_redis
```

The `bosh_cli` gem is currently only available from S3, rather than RubyGem itself. So it needs to be installed first.

## Usage

Each time you install the latest `redis-cf-plugin` you will want to re-upload the latest available redis release to your bosh. If no newer release is available then nothing good nor bad will occur.

```
$ bosh prepare redis
Uploading new redis release to bosh...
```

To create/provision a new redis service you run the following command. By default, it will select the smallest known instance size.

```
$ bosh create redis
$ bosh create redis --size small
$ bosh create redis --size medium
$ bosh create redis --size large
$ bosh create redis --size xlarge
```

By default the redis server is assigned a 4096 Mb persistent volume/disk. To change this value use `--disk`:

```
$ bosh create redis myapp-redis --disk 8192
```

NOTE: By default, the `default` security group is used. It must have port `6379` open.

To chose a different security group, use the `--security-group` option:

```
$ bosh create redis --security-group redis-server
```

To see the list of available instance sizes or to edit the list of available instance size, see the section "Customizing" below.

* TODO - how to show available instance sizes
* TODO - how to update a redis server to a different instance size/flavor
* TODO - how to update the persistent disk for the redis server

## Customizing

* TODO - how to edit available instance sizes (via the bosh deployment file templates)

## Releasing new plugin gem versions

There are two reasons to release new versions of this plugin.

1. Package the latest [redis-boshrelease](https://github.com/cloudfoundry-community/redis-boshrelease) bosh release (which describes how the redis service is implemented)
2. New features or bug fixes to the plugin

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

To locally test the plugin (`bosh` cli loads plugins from its local path automatically):

```
$ cf /path/to/bosh_cli_plugin_redis
$ bosh redis
```

To release a new version of the plugin as a RubyGem:

1. Edit `bosh_cli_plugin_redis.gemspec` to update the major or minor or patch version.
2. Run the release command:

```
$ rake release
```

## Contributing

For fixes or features to the `bosh_cli_plugin_redis` (`bosh redis`) plugin:

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

For fixes or features to the redis bosh release, please visit https://github.com/cloudfoundry-community/redis-boshrelease. Final releases of `redis-boshrelease` will be distributed in future gem versions of this plugin.
