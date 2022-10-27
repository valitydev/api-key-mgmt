defprotocol ApiKeyMgmt.Auth.BouncerEntity do
  @moduledoc """
  Protocol used to convert a struct into a Bouncer entity.
  """
  @spec to_bouncer_entity(t) :: Bouncer.Base.Entity.t()
  def to_bouncer_entity(term)
end
