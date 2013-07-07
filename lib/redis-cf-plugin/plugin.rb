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

    # TODO - size must be valid
    # TODO - name must be unique (cf services & bosh deployments)

    desc "Create a Redis service deployed upon target bosh"
    group :services, :manage
    input :name, desc: "Unique name for service (within bosh & cloud foundry)"
    input :size, desc: "Size of provisioned VMs", default: "small"
    input :security_group, desc: "Security group to assign to provisioned VMs", default: "default"
    def create_redis
      require "cli" # bosh_cli's director client library
      service_name = input[:name] || "redis-#{Time.now.to_i}"
      resource_size = input[:size]
      security_group = input[:security_group]

      bosh_uuid = bosh_director_client.get_status["uuid"]
      bosh_cpi = bosh_director_client.get_status["cpi"]

      template_file = File.join(bosh_release_dir, "templates", bosh_cpi, "single_vm.yml.erb")

      # Create an initial deployment file; upon which the CPI-specific template will be applied below
      # Initial file will look like:
      # ---
      # name: NAME
      # director_uuid: UUID
      # networks: {}
      # properties:
      #   redis:
      #     resource: medium
      #     security_group: redis-server
      deployment_file = "deployments/redis/#{service_name}.yml"
      sh "mkdir -p deployments/redis"
      line "Creating deployment file #{deployment_file}..."
      File.open(deployment_file, "w") do |file|
        file << {
          "name" => service_name,
          "director_uuid" => bosh_uuid,
          "networks" => {},
          "properties" => {
            "redis" => {
              "resource" => resource_size,
              "security_group" => security_group
            }
          }
        }.to_yaml
      end

      sh "bosh deployment #{deployment_file}"
      sh "bosh -n diff #{template_file}"
      sh "bosh -n deploy"
    end

    desc "Bind current Redis service URI to current app via env variable"
    input :app, argument: "required", desc: "Application to immediately bind to", from_given: by_name(:app)
    input :env_var, desc: "Environment variable to bind redis URI (default $REDIS_URI)", default: "REDIS_URI"
    group :services, :manage
    def bind_redis_env_var
      load_bosh_and_validate_current_deployment
      p env_var = input[:env_var]
      p app = input[:app]
    end


    desc "Delete current Redis service"
    group :services, :manage
    def delete_redis
      load_bosh_and_validate_current_deployment
      sh "bosh delete deployment #{deployment_name}"
    end

    protected
    def release_name
      "redis"
    end

    def bosh_release_dir
      File.expand_path("../../../bosh_release", __FILE__)
    end

    def within_bosh_release(&block)
      chdir(bosh_release_dir, &block)
    end

    def bosh_director_client
      @bosh_director_client ||= ::Bosh::Cli::Command::Base.new.director
    end

    def deployment_file
      @current_deployment_file ||= ::Bosh::Cli::Command::Deployment.new.deployment
    end

    def load_bosh_and_validate_current_deployment
      require "cli" # bosh_cli's director client library
      unless File.exists?(deployment_file)
        fail "Target deployment file no longer exists: #{deployment_file}"
      end
      @deployment = YAML.load_file(deployment_file)
      unless @deployment["release"] && @deployment["release"]["name"] == release_name
        fail "Target deployment file is not for redis service: #{deployment_file}"
      end
    end

    def deployment_name
      @deployment["name"]
    end
  end
end
