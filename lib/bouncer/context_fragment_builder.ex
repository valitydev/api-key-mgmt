defmodule Bouncer.ContextFragmentBuilder do
  @moduledoc """
  A ContextFragment builder. Feel free to import where needed.
  """
  alias Bouncer.Base.Entity
  alias Bouncer.Context.ContextFragment, as: BakedContextFragment
  alias Bouncer.Context.ContextFragmentType
  alias Bouncer.Context.V1.ContextFragment
  alias Bouncer.ContextFragmentBuilder.Helper

  @doc ~S"""
  Starts building a new context fragment. Utilize the ther functions in this module to shape it to your liking.

  ## Examples

      iex> build()
      %ContextFragment{}

  """
  @spec build :: ContextFragment.t()
  def build do
    ContextFragment.new()
  end

  @doc ~S"""
  Sets environment data of a context. If `iso8601_datetime` is missing it gets automatically populated with current time.

  ## Examples
      iex> build() |> environment(~U[2022-10-26T17:02:28.339227Z], "my_deployment")
      %ContextFragment{
        env: %Environment{
          now: "2022-10-26T17:02:28.339227Z",
          deployment: %Deployment{
            id: "my_deployment"
          }
        }
      }

  """
  @spec environment(
          ContextFragment.t(),
          datetime_now :: DateTime.t() | nil,
          deployment_id :: String.t()
        ) :: ContextFragment.t()
  def environment(context_fragment, datetime_now \\ nil, deployment_id) do
    %{context_fragment | env: Helper.environment(datetime_now, deployment_id)}
  end

  @doc ~S"""
  Sets auth data of a context.

  ## Examples
      iex> build() |> auth("ApiKeyToken", "mytokenid")
      %ContextFragment{
        auth: %Auth{
          method: "ApiKeyToken",
          expiration: nil,
          scope: MapSet.new(),
          token: %Token{id: "mytokenid"}
        }
      }

      iex> build() |> auth("ApiKeyToken", "2022-10-26T17:02:28.339227Z", "mytokenid")
      %ContextFragment{
        auth: %Auth{
          method: "ApiKeyToken",
          expiration: "2022-10-26T17:02:28.339227Z",
          scope: MapSet.new(),
          token: %Token{id: "mytokenid"}
        }
      }

      iex> build() |> auth("ApiKeyToken", "2022-10-26T17:02:28.339227Z", "mytokenid", party: "mypartyid")
      %ContextFragment{
        auth: %Auth{
          method: "ApiKeyToken",
          expiration: "2022-10-26T17:02:28.339227Z",
          scope: MapSet.new([
            %AuthScope{
              party: %Entity{id: "mypartyid"}
            }
          ]),
          token: %Token{id: "mytokenid"}
        }
      }

  """
  @spec auth(
          ContextFragment.t(),
          method :: String.t(),
          expiration :: String.t() | nil,
          token_id :: String.t(),
          scopes :: Keyword.t()
        ) :: ContextFragment.t()
  def auth(context_fragment, method, expiration \\ nil, token_id, scopes \\ []) do
    %{context_fragment | auth: Helper.auth(method, expiration, token_id, scopes)}
  end

  @doc ~S"""
  Sets requester data of a context.

  ## Examples
      iex> build() |> requester("localhost")
      %ContextFragment{
        requester: %Requester{
          ip: "localhost"
        }
      }

  """
  @spec requester(
          ContextFragment.t(),
          ip_address :: String.t()
        ) :: ContextFragment.t()
  def requester(context_fragment, ip_address) do
    %{context_fragment | requester: Helper.requester(ip_address)}
  end

  @doc ~S"""
  Sets apikeymgmt operation data of a context.

  ## Examples
      iex> build() |> apikeymgmt("MyOperation", %Entity{id: "42"}, %Entity{id: "24"})
      %ContextFragment{
        apikeymgmt: %ContextApiKeyMgmt{
          op: %ApiKeyMgmtOperation{
            id: "MyOperation",
            organization: %Entity{id: "42"},
            api_key: %Entity{id: "24"}
          }
        }
      }

      iex> build() |> apikeymgmt("MyOperation", %Entity{id: "42"})
      %ContextFragment{
        apikeymgmt: %ContextApiKeyMgmt{
          op: %ApiKeyMgmtOperation{
            id: "MyOperation",
            organization: %Entity{id: "42"},
            api_key: nil
          }
        }
      }

      iex> build() |> apikeymgmt("MyOperation")
      %ContextFragment{
        apikeymgmt: %ContextApiKeyMgmt{
          op: %ApiKeyMgmtOperation{
            id: "MyOperation",
            organization: nil,
            api_key: nil
          }
        }
      }
  """
  @spec apikeymgmt(
          ContextFragment.t(),
          operation_id :: String.t(),
          organization :: Entity.t() | nil,
          api_key :: Entity.t() | nil
        ) :: ContextFragment.t()
  def apikeymgmt(context_fragment, operation_id, organization \\ nil, api_key \\ nil) do
    %{
      context_fragment
      | apikeymgmt: Helper.apikeymgmt(operation_id, organization, api_key)
    }
  end

  @doc ~S"""
  Adds an entity data to a context.

  ## Examples
      iex> build() |> entity(%Entity{id: "42"})
      %ContextFragment{
        entities: MapSet.new([%Entity{id: "42"}])
      }

      iex> build() |> entity(%Entity{id: "42"}) |> entity(%Entity{id: "42"})
      %ContextFragment{
        entities: MapSet.new([%Entity{id: "42"}])
      }

      iex> build() |> entity(%Entity{id: "42"}) |> entity(%Entity{id: "24"})
      %ContextFragment{
        entities: MapSet.new([%Entity{id: "42"}, %Entity{id: "24"}])
      }
  """
  @spec entity(
          ContextFragment.t(),
          Entity.t()
        ) :: ContextFragment.t()
  def entity(context_fragment, entity) do
    entities = context_fragment.entities || MapSet.new()
    %{context_fragment | entities: entities |> MapSet.put(entity)}
  end

  @doc ~S"""
  Finalizes a context fragment by serializing it to a binary format.

  ## Examples
      iex> build() |> bake()
      %BakedContextFragment{
        type: ContextFragmentType.v1_thrift_binary(),
        content: :erlang.iolist_to_binary(ContextFragment.serialize(build()))
      }

  """
  @spec bake(ContextFragment.t()) :: BakedContextFragment.t()
  def bake(context_fragment) do
    require ContextFragmentType

    %BakedContextFragment{
      type: ContextFragmentType.v1_thrift_binary(),
      content: context_fragment |> ContextFragment.serialize() |> :erlang.iolist_to_binary()
    }
  end
end
