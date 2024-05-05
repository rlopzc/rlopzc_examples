import Config

config :libcluster,
  topologies: [
    local_epmd: [
      strategy: Cluster.Strategy.LocalEpmd
    ]
  ]

import_config "#{config_env()}.exs"
