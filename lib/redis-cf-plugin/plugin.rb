module RedisCfPlugin
  class Plugin < CF::CLI

    desc "Prepare target bosh for deploying one or more Redis services"
    group :services, :manage
    def prepare_redis
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
  end
end
