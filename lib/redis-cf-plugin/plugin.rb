require "yaml"

# for the #sh helper
require "rake"
require "rake/file_utils"

module RedisCfPlugin
  class Plugin < CF::CLI
    include FileUtils

    desc "Prepare target bosh for deploying one or more Redis services"
    group :services, :manage
    def prepare_redis
      within_bosh_release do
        # the releases/index.yml contains all the available release versions in an unordered
        # hash of hashes in YAML format:
        #     --- 
        #     builds: 
        #       af61f03c5ad6327e0795402f1c458f2fc6f21201: 
        #         version: 3
        #       39c029d0af9effc6913f3333434b894ff6433638: 
        #         version: 1
        #       5f5d0a7fb577fec3c09408c94f7abbe2d52a042c: 
        #         version: 4
        #       f044d47e0183f084db9dac5a6ef00d7bd21c8451: 
        #         version: 2
        release_index = YAML.load_file("releases/index.yml")
        latest_version = release_index["builds"].values.inject(0) do |max_version, release|
          version = release["version"]
          max_version < version ? version : max_version
        end

        sh "bosh upload release releases/*-#{latest_version}.yml"
      end
    end

    desc "Create a Redis service deployed upon target bosh"
    group :services, :manage
    def create_redis
    end

    desc "Bind current Redis service URI to current app via env variable"
    input :app, argument: "required", desc: "Application to immediately bind to", from_given: by_name(:app)
    input :env_var, desc: "Environment variable to bind redis URI (default $REDIS_URI)", default: "REDIS_URI"
    group :services, :manage
    def bind_redis_env_var
      p env_var = input[:env_var]
      p app = input[:app]
    end

    protected
    def within_bosh_release(&block)
      bosh_release_dir = File.expand_path("../../../bosh_release", __FILE__)
      chdir(bosh_release_dir, &block)
    end
  end
end
