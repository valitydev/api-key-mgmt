# Used by "mix format"
[
  import_deps: [:plug, :ecto],
  inputs: [
    "{mix,.formatter,.credo}.exs",
    "config/*.exs",
    "priv/repository/migrations/*.exs",
    "apps/**/{lib,test}/**/*.{ex,exs}"
  ]
]
