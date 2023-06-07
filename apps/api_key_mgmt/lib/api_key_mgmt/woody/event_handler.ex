defmodule ApiKeyMgmt.Woody.EventHandler do
  @moduledoc false

  alias :woody_event_handler, as: WoodyEventHandler

  require Logger

  # @behaviour WoodyEventHandler

  @typep event :: WoodyEventHandler.event()
  @typep meta :: WoodyEventHandler.meta()

  # @exposed_meta [
  #   :event,
  #   :service,
  #   :function,
  #   :type,
  #   :metadata,
  #   :url,
  #   :deadline,
  #   :execution_duration_ms
  # ]

  @spec handle_event(event(), Woody.Context.rpc_id(), meta(), any()) ::
          any
  def handle_event(event, rpc_id, meta, _opts) do
    Logger.info(inspect({event, rpc_id, meta}))
    # level = WoodyEventHandler.get_event_severity(event, meta)
    # message = Woody.EventHandler.Formatter.format(rpc_id, event, meta)
    # metadata = WoodyEventHandler.format_meta(event, meta, @exposed_meta)

    # Logger.log(level, message, metadata)
  end
end
