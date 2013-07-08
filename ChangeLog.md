# Change Log


## v0.2 - bosh_cli_plugin_redis

Converted into a bosh plugin. Prefix "bosh" to the sub-commands below:

    prepare redis 
        Prepare bosh for deploying one or more Redis services 

    create redis [--name] [--size] [--security_group] 
        Create a Redis service deployed upon target bosh 
        --name           Unique name for service (within bosh & cloud foundry) 
        --size           Size of provisioned VMs 
        --security_group Security group to assign to provisioned VMs 

    show redis uri 
        Show the redis URI for connection via bosh DNS 

    delete redis 
        Delete current Redis service 

Note: the `cf bind-redis-env-var` command has been removed as it is a) specific to a Cloud Foundry user not a bosh user; b) kinda crappy "services" integration. Perhaps move it back into a cf plugin in future.

Other features/fixes:

* Validates the resource size with available sizes in the template [v0.2.1]

## v0.1 - redis-cf-plugin

Initial release! The initial commands offered are:

    cf create-redis               Create a Redis service deployed upon target bosh
    cf show-redis-uri             Show the redis URI for connection via bosh DNS
    cf bind-redis-env-var APP     Bind current Redis service URI to current app via env variable
    cf delete-redis               Delete current Redis service

The redis service URI uses bosh DNS. As such it must be deployed into the same bosh being used for Cloud Foundry.
