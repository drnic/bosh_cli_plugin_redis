require "yaml"

# for the #sh helper
require "rake"
require "rake/file_utils"

module Bosh::Cli::Command
  class Redis < Base
    include FileUtils
    include Bosh::Cli::Validation

    usage "redis"
    desc  "show micro bosh sub-commands"
    def redis_help
      say("bosh redis sub-commands:")
      nl
      cmds = Bosh::Cli::Config.commands.values.find_all {|c|
        c.usage =~ /redis/
      }
      Bosh::Cli::Command::Help.list_commands(cmds)
    end

    usage "prepare redis"
    desc "Prepare bosh for deploying one or more Redis services"
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

    usage "create redis"
    desc "Create a Redis service deployed upon target bosh"
    option "--name redis-<timestamp>", String, "Unique bosh deployment name"
    option "--size small", String, "Size of provisioned VMs"
    option "--security-group default", String, "Security group to assign to provisioned VMs"
    def create_redis
      auth_required

      service_name = options[:name] || default_name
      resource_size = options[:size] || default_size
      security_group = options[:security_group] || default_security_group
      redis_port = 6379

      bosh_status # preload
      nl
      say "CPI: #{bosh_cpi}"
      say "Deployment name: #{service_name.make_green}"
      say "Resource size: #{resource_size.make_green}"
      say "Security group: #{security_group.make_green}"
      nl
      unless confirmed?("Security group exists with ports 22 & #{redis_port}")
        cancel_deployment
      end
      unless confirmed?("Creating redis service")
        cancel_deployment
      end

      template_file = template_file("single_vm.yml.erb")

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
      step("Checking/creating #{redis_deployments_store_path} for deployment files",
           "Failed to create #{redis_deployments_store_path} for deployment files", :fatal) do
        mkdir_p(redis_deployments_store_path)
      end

      step("Creating deployment file #{deployment_file}",
           "Failed to create deployment file #{deployment_file}", :fatal) do
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
      end
      nl

      deployment_cmd.set_current(deployment_file)
      biff_cmd.biff(template_file)
      deployment_cmd.perform
    end

    usage "show redis uri"
    desc "Show the redis URI for connection via bosh DNS"
    def show_redis_uri
      load_bosh_and_validate_current_deployment
      print service_uri
    end

    usage "delete redis"
    desc "Delete current Redis service"
    def delete_redis
      load_bosh_and_validate_current_deployment
      sh "bosh delete deployment #{deployment_name}"
    end

    protected

    def default_name
      "redis-#{Time.now.to_i}"
    end

    def default_size
      "small"
    end

    def default_security_group
      "default"
    end

    def release_name
      "redis"
    end

    def redis_deployments_store_path
      "deployments/redis"
    end

    def bosh_release_dir
      File.expand_path("../../../../../bosh_release", __FILE__)
    end

    def within_bosh_release(&block)
      chdir(bosh_release_dir, &block)
    end

    def bosh_status
      @bosh_status ||= begin
        step("Fetching bosh information", "Cannot fetch bosh information", :fatal) do
           @bosh_status = bosh_director_client.get_status
        end
        @bosh_status
      end
    end

    def bosh_uuid
      bosh_status["uuid"]
    end

    def bosh_cpi
      bosh_status["cpi"]
    end

    def template_file(file)
      File.join(bosh_release_dir, "templates", bosh_cpi, file)
    end

    # TODO this is now a bosh cli command itself; use #director
    def bosh_director_client
      director
    end

    def deployment_cmd
      @deployment_cmd ||= begin
        cmd = Bosh::Cli::Command::Deployment.new
        cmd.add_option :non_interactive, true
        cmd
      end
    end

    def biff_cmd
      @biff_cmd ||= begin
        cmd = Bosh::Cli::Command::Biff.new
        cmd.add_option :non_interactive, true
        cmd
      end
    end

    # TODO this is now a bosh cli command itself
    def deployment_file
      @current_deployment_file ||= ::Bosh::Cli::Command::Deployment.new.deployment
    end

    # TODO use bosh cli helpers to validate/require this
    def load_bosh_and_validate_current_deployment
      auth_required
      unless File.exists?(deployment_file)
        err "Target deployment file no longer exists: #{deployment_file}"
      end
      @deployment = YAML.load_file(deployment_file)
      unless @deployment["release"] && @deployment["release"]["name"] == release_name
        err "Target deployment file is not for redis service: #{deployment_file}"
      end
    end

    def deployment_name
      @deployment["name"]
    end

    def service_uri
      password = @deployment["properties"]["redis"]["password"]
      port = @deployment["properties"]["redis"]["port"]
      db = 0
      "redis://:#{password}@#{server_host}:#{port}/#{db}"
    end

    # returns the first DNS entry for the running instance
    def server_host
      @server_host ||= begin
        vms = bosh_director_client.fetch_vm_state(deployment_name, use_cache: false)
        if vms.empty?
          err "Deployment has no running instances"
        end
        if vms.size > 1
          say "#{"WARNING!".make_red} Deployment has more than 1 running instance (#{vms.size}); using first instance"
        end
        vm = vms.first
        vm["dns"].first
      end
    end
  end
end
