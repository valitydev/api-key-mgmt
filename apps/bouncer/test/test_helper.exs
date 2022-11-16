Mox.defmock(Bouncer.MockClient, for: Bouncer.Client)
Application.put_env(:bouncer, :client_impl, Bouncer.MockClient)

ExUnit.start()
