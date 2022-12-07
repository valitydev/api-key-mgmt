defmodule ApiKeyMgmt.ReleaseTasks do
  @moduledoc """
  Helper functions for use with releases eval command.
  """
  @app :api_key_mgmt

  # coveralls-ignore-start
  @doc """
    Migrate the database. Defaults to migrating to the latest, `[all: true]`
    Also accepts `[step: 1]`, or `[to: 20200118045751]`

    Usage: bin/api_key_mgmt eval "ApiKeyMgmt.ReleaseTasks.migrate([all: true])"
  """
  @spec migrate(Keyword.t()) :: any
  def migrate(opts \\ [all: true]) do
    for repo <- repos() do
      {:ok, _run_return, _apps} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, opts))
    end
  end

  @doc """
    Rollback migrations to version. For versions see `migration_status/0`.
    Usage: bin/api_key_mgmt  eval 'ApiKeyMgmt.ReleaseTasks.rollback(ApiKeyMgmt.Repository, version)'
  """
  @spec rollback(ApiKeyMgmt.Repository, any) :: any
  def rollback(repo, version) do
    {:ok, _run_return, _apps} =
      Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  @doc """
    Print the migration status for configured Repos' migrations.
    Usage: bin/api_key_mgmt eval 'ApiKeyMgmt.ReleaseTasks.migration_status()'
  """
  @spec migration_status :: any
  def migration_status do
    for repo <- repos(), do: print_migrations_for(repo)
  end

  # coveralls-ignore-end

  ##

  defp repos do
    Application.load(@app)
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp print_migrations_for(repo) do
    paths = repo_migrations_path(repo)

    {:ok, repo_status, _apps} =
      Ecto.Migrator.with_repo(repo, &Ecto.Migrator.migrations(&1, paths), mode: :temporary)

    # credo:disable-for-next-line
    IO.puts(
      """
      Repo: #{inspect(repo)}
        Status    Migration ID    Migration Name
      --------------------------------------------------
      """ <>
        Enum.map_join(repo_status, "\n", fn {status, number, description} ->
          "  #{pad(status, 10)}#{pad(number, 16)}#{description}"
        end) <> "\n"
    )
  end

  defp repo_migrations_path(repo) do
    config = repo.config()
    priv = config[:priv] || "priv/#{repo |> Module.split() |> List.last() |> Macro.underscore()}"
    config |> Keyword.fetch!(:otp_app) |> Application.app_dir() |> Path.join(priv)
  end

  defp pad(content, pad) do
    content
    |> to_string
    |> String.pad_trailing(pad)
  end
end
