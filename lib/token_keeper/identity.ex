defmodule TokenKeeper.Identity do
  @moduledoc """
  An abstraction for an identity of authenticated user interpeted from AuthData.
  """
  alias Bouncer.Context.ContextFragment
  alias TokenKeeper.Keeper.AuthData

  defmodule User do
    @moduledoc """
    User identity
    """
    @enforce_keys [:id]
    defstruct [:id, :email, :realm]

    @type t() :: %__MODULE__{
            id: String.t(),
            email: String.t() | nil,
            realm: String.t() | nil
          }
  end

  defmodule Party do
    @moduledoc """
    Party identity
    """
    @enforce_keys [:id]
    defstruct [:id]

    @type t() :: %__MODULE__{
            id: String.t()
          }
  end

  defstruct [:bouncer_fragment, :type]

  @type type() :: User.t() | Party.t()
  @type t() :: %__MODULE__{
          type: type() | nil,
          bouncer_fragment: ContextFragment.t()
        }

  @spec from_authdata(AuthData.t(), Keyword.t() | nil) :: t()
  def from_authdata(authdata, opts \\ nil) do
    %__MODULE__{
      type: type_from_metadata(authdata.metadata, opts[:metadata_mapping]),
      bouncer_fragment: authdata.context
    }
  end

  @spec to_context_metadata(t(), Keyword.t() | nil) :: {ContextFragment.t(), metadata :: map()}
  def to_context_metadata(identity, opts \\ nil) do
    {identity.bouncer_fragment, type_to_metadata(identity.type, opts[:metadata_mapping])}
  end

  ##

  defp type_to_metadata(type, mapping \\ nil) do
    mapping = mapping || default_mapping()
    mapping = mapping |> Enum.into(%{}, fn {k, v} -> {v, k} end)

    metadata =
      case type do
        %Party{id: id} ->
          %{party_id: id}

        %User{id: id, email: email, realm: realm} ->
          %{user_id: id, user_email: email, user_realm: realm}
      end

    map_metadata(metadata, mapping)
  end

  defp type_from_metadata(metadata, mapping \\ nil) do
    metadata = map_metadata(metadata || %{}, mapping || default_mapping())

    case metadata do
      %{party_id: _, user_id: _} ->
        :unknown

      %{party_id: id} ->
        %Party{id: id}

      %{user_id: id} = user ->
        %User{id: id, email: Map.get(user, :user_email), realm: Map.get(user, :user_realm)}

      _unknown ->
        :unknown
    end
  end

  defp map_metadata(metadata, mapping) do
    mapping
    |> Enum.into(%{}, fn {k, v} -> {k, Map.get(metadata, v)} end)
    |> Map.reject(fn {_, v} -> v == nil end)
  end

  defp default_mapping do
    %{
      party_id: "party.id",
      user_id: "user.id",
      user_email: "user.email",
      user_realm: "user.realm"
    }
  end
end
