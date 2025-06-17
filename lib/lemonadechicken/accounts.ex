defmodule Lemonadechicken.Accounts do
  use Ash.Domain, otp_app: :lemonadechicken, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource Lemonadechicken.Accounts.Token
    resource Lemonadechicken.Accounts.User
  end
end
