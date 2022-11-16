defmodule TestSupport.ApiKeyManagement.Auth.TestEntity do
  @moduledoc false
  defstruct id: nil
  @type t() :: %__MODULE__{id: String.t()}
end

defimpl ApiKeyMgmt.Auth.BouncerEntity, for: TestSupport.ApiKeyManagement.Auth.TestEntity do
  alias TestSupport.ApiKeyManagement.Auth.TestEntity
  alias Bouncer.Base.Entity

  @spec to_bouncer_entity(TestEntity.t()) :: Entity.t()
  def to_bouncer_entity(entity) do
    %Entity{
      id: entity.id,
      type: "TestEntity"
    }
  end
end
