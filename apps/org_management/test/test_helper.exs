Mox.defmock(OrgManagement.MockClient, for: OrgManagement.Client)
Application.put_env(:org_management, :client_impl, OrgManagement.MockClient)

ExUnit.start()
