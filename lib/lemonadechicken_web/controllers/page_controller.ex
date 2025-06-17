defmodule LemonadechickenWeb.PageController do
  use LemonadechickenWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
