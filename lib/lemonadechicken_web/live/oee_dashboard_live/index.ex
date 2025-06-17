defmodule LemonadechickenWeb.OEEDashboardLive.Index do
  use LemonadechickenWeb, :live_view
  alias Lemonadechicken.Manufacturing

  # Add interval definitions for the chart timeframes
  @intervals %{
    last_1h: {60, 5},     # 5 minute intervals for 1 hour
    last_4h: {240, 15},   # 15 minute intervals for 4 hours
    last_8h: {480, 30},   # 30 minute intervals for 8 hours
    last_12h: {720, 30},  # 30 minute intervals for 12 hours
    last_24h: {1440, 60}, # 60 minute intervals for 24 hours
    last_7d: {10080, 240}, # 4 hour intervals for 7 days
    last_30d: {43200, 720} # 12 hour intervals for 30 days
  }

  @default_metrics %{oee: 0.0, availability: 0.0, performance: 0.0, quality: 0.0}

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "OEE Dashboard")
      |> assign(:selected_scope, :machine)
      |> assign(:selected_id, nil)
      |> assign(:date_range, :last_24h)
      |> assign(:chart_type, :line)
      |> assign(:loading, false)
      |> assign(:error, nil)
      |> assign(:metrics, @default_metrics)
      |> assign(:intervals, [])
      |> assign_hierarchy_data()

    if connected?(socket), do: Process.send_after(self(), :refresh_metrics, 60_000)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      case params do
        %{"scope" => scope, "id" => id} ->
          scope = String.to_existing_atom(scope)
          socket
          |> assign(:selected_scope, scope)
          |> assign(:selected_id, id)
          |> load_metrics()

        _ ->
          socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("select_scope", %{"scope" => scope}, socket) do
    {:noreply,
     socket
     |> assign(:selected_scope, String.to_existing_atom(scope))
     |> assign(:selected_id, nil)
     |> assign(:metrics, @default_metrics)
     |> assign(:intervals, [])}
  end

  @impl true
  def handle_event("select_item", %{"id" => id}, socket) do
    {:noreply,
     socket
     |> assign(:selected_id, id)
     |> load_metrics()}
  end

  @impl true
  def handle_event("change_date_range", %{"range" => range}, socket) do
    {:noreply,
     socket
     |> assign(:date_range, String.to_existing_atom(range))
     |> load_metrics()}
  end

  @impl true
  def handle_event("change_chart_type", %{"type" => type}, socket) do
    {:noreply,
     socket
     |> assign(:chart_type, String.to_existing_atom(type))}
  end

  @impl true
  def handle_info(:refresh_metrics, socket) do
    Process.send_after(self(), :refresh_metrics, 60_000)

    socket =
      if socket.assigns.selected_id,
        do: load_metrics(socket),
        else: socket

    {:noreply, socket}
  end

  defp assign_hierarchy_data(socket) do
    assign(socket,
      plants: Manufacturing.list_plants!(),
      areas: Manufacturing.list_areas!(),
      lines: Manufacturing.list_lines!(),
      machines: Manufacturing.list_machines!()
    )
  end

  defp load_metrics(%{assigns: %{selected_scope: scope, selected_id: nil}} = socket) do
    assign(socket,
      metrics: @default_metrics,
      intervals: [],
      loading: false,
      error: nil
    )
  end

  defp load_metrics(%{assigns: %{selected_scope: scope, selected_id: id, date_range: range}} = socket) do
    Task.async(fn -> Manufacturing.get_oee_metrics(scope, id, range) end)

    assign(socket,
      loading: true,
      error: nil
    )
  end

  defp load_metrics(socket), do: socket

  @impl true
  def handle_info({ref, {:ok, %{metrics: metrics, intervals: intervals}}}, socket) do
    Process.demonitor(ref, [:flush])

    {:noreply,
     socket
     |> assign(:loading, false)
     |> assign(:error, nil)
     |> assign(:metrics, metrics)
     |> assign(:intervals, intervals)}
  end

  @impl true
  def handle_info({ref, {:error, error}}, socket) do
    Process.demonitor(ref, [:flush])

    {:noreply,
     socket
     |> assign(:loading, false)
     |> assign(:error, error)
     |> assign(:metrics, @default_metrics)
     |> assign(:intervals, [])}
  end

  # Handle the :DOWN message from the Task
  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, socket) do
    {:noreply, socket}
  end
end
