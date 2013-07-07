# Change Log


## v0.1

Initial release! The initial commands offered are:

    cf create-redis               Create a Redis service deployed upon target bosh
    cf show-redis-uri             Show the redis URI for connection via bosh DNS
    cf bind-redis-env-var APP     Bind current Redis service URI to current app via env variable
    cf delete-redis               Delete current Redis service

The redis service URI uses bosh DNS. As such it must be deployed into the same bosh being used for Cloud Foundry.
