defmodule Lemonadechicken.Manufacturing do
  @moduledoc """
  Manufacturing domain for Lemonadechicken.
  Handles manufacturing resources like plants, areas, lines, machines, and their related operations.
  """
  use Ash.Domain,
    otp_app: :lemonadechicken,
    extensions: [AshAi]

  alias Lemonadechicken.Manufacturing.{Plant, Area, Line, Machine, MachineStatus, TimeTracker, ProductionRun}
  require Ash.Query

  # Domain configuration
  resources do
    resource Lemonadechicken.Manufacturing.Plant do
      define :create_plant, action: :create
      define :list_plants, action: :read
      define :get_plant, action: :read, get_by: :id
      define :update_plant, action: :update
      define :delete_plant, action: :destroy
    end

    resource Lemonadechicken.Manufacturing.Area do
      define :create_area, action: :create
      define :list_areas, action: :read
      define :get_area, action: :read, get_by: :id
      define :update_area, action: :update
      define :delete_area, action: :destroy
    end

    resource Lemonadechicken.Manufacturing.Line do
      define :create_line, action: :create
      define :list_lines, action: :read
      define :get_line, action: :read, get_by: :id
      define :update_line, action: :update
      define :delete_line, action: :destroy
    end

    resource Lemonadechicken.Manufacturing.Machine do
      define :create_machine, action: :create
      define :list_machines, action: :read
      define :get_machine, action: :read, get_by: :id
      define :update_machine, action: :update
      define :change_status, action: :change_status
      define :delete_machine, action: :destroy
    end

    resource Lemonadechicken.Manufacturing.ProductionRun do
      define :create_run, action: :create
      define :list_runs, action: :read
      define :get_run, action: :read, get_by: :id
      define :update_run, action: :update
      define :delete_run, action: :destroy
    end

    resource Lemonadechicken.Manufacturing.MachineStatus do
      define :create_status, action: :create
      define :list_statuses, action: :read
      define :get_status, action: :read, get_by: :id
      define :update_status, action: :update
      define :delete_status, action: :destroy
    end

    resource Lemonadechicken.Manufacturing.TimeTracker do
      define :create_tracker, action: :create
      define :list_trackers, action: :read
      define :get_tracker, action: :read, get_by: :id
      define :update_tracker, action: :update
      define :delete_tracker, action: :destroy
      define :start_downtime, action: :start_downtime
      define :end_downtime, action: :end_downtime
    end
  end

  tools do
    # Read operations
    tool :list_plants, Lemonadechicken.Manufacturing.Plant, :read do
      description "List all manufacturing plants"
    end
    tool :list_areas, Lemonadechicken.Manufacturing.Area, :read do
      description "List all manufacturing areas"
    end
    tool :list_lines, Lemonadechicken.Manufacturing.Line, :read do
      description "List all production lines"
    end
    tool :list_machines, Lemonadechicken.Manufacturing.Machine, :read do
      description "List all machines"
    end
    tool :list_runs, Lemonadechicken.Manufacturing.ProductionRun, :read do
      description "List all production runs"
    end
    tool :list_statuses, Lemonadechicken.Manufacturing.MachineStatus, :read do
      description "List all machine statuses"
    end
    tool :list_trackers, Lemonadechicken.Manufacturing.TimeTracker, :read do
      description "List all time trackers"
    end

    # Create operations
    tool :create_plant, Lemonadechicken.Manufacturing.Plant, :create do
      description "Create a new manufacturing plant"
    end
    tool :create_area, Lemonadechicken.Manufacturing.Area, :create do
      description "Create a new manufacturing area"
    end
    tool :create_line, Lemonadechicken.Manufacturing.Line, :create do
      description "Create a new production line"
    end
    tool :create_machine, Lemonadechicken.Manufacturing.Machine, :create do
      description "Create a new machine"
    end
    tool :create_run, Lemonadechicken.Manufacturing.ProductionRun, :create do
      description "Create a new production run"
    end
    tool :create_status, Lemonadechicken.Manufacturing.MachineStatus, :create do
      description "Create a new machine status"
    end
    tool :create_tracker, Lemonadechicken.Manufacturing.TimeTracker, :create do
      description "Create a new time tracker"
    end

    # Update operations
    tool :update_plant, Lemonadechicken.Manufacturing.Plant, :update do
      description "Update a manufacturing plant"
    end
    tool :update_area, Lemonadechicken.Manufacturing.Area, :update do
      description "Update a manufacturing area"
    end
    tool :update_line, Lemonadechicken.Manufacturing.Line, :update do
      description "Update a production line"
    end
    tool :update_machine, Lemonadechicken.Manufacturing.Machine, :update do
      description "Update a machine"
    end
    tool :update_run, Lemonadechicken.Manufacturing.ProductionRun, :update do
      description "Update a production run"
    end
    tool :update_status, Lemonadechicken.Manufacturing.MachineStatus, :update do
      description "Update a machine status"
    end
    tool :update_tracker, Lemonadechicken.Manufacturing.TimeTracker, :update do
      description "Update a time tracker"
    end

    # Delete operations
    tool :delete_plant, Lemonadechicken.Manufacturing.Plant, :destroy do
      description "Delete a manufacturing plant"
    end
    tool :delete_area, Lemonadechicken.Manufacturing.Area, :destroy do
      description "Delete a manufacturing area"
    end
    tool :delete_line, Lemonadechicken.Manufacturing.Line, :destroy do
      description "Delete a production line"
    end
    tool :delete_machine, Lemonadechicken.Manufacturing.Machine, :destroy do
      description "Delete a machine"
    end
    tool :delete_run, Lemonadechicken.Manufacturing.ProductionRun, :destroy do
      description "Delete a production run"
    end
    tool :delete_status, Lemonadechicken.Manufacturing.MachineStatus, :destroy do
      description "Delete a machine status"
    end
    tool :delete_tracker, Lemonadechicken.Manufacturing.TimeTracker, :destroy do
      description "Delete a time tracker"
    end

    # Special operations
    tool :change_machine_status, Lemonadechicken.Manufacturing.Machine, :change_status do
      description "Change the status of a machine"
    end
    tool :start_downtime, Lemonadechicken.Manufacturing.TimeTracker, :start_downtime do
      description "Start tracking machine downtime"
    end
    tool :end_downtime, Lemonadechicken.Manufacturing.TimeTracker, :end_downtime do
      description "End tracking machine downtime"
    end
  end

  # CRUD functions (list, get, etc.)
  def list_plants!(opts \\ []), do: Plant |> Ash.Query.sort(name: :asc) |> read!(opts)
  def list_areas!(opts \\ []), do: Area |> Ash.Query.sort(name: :asc) |> read!(opts)
  def list_lines!(opts \\ []), do: Line |> Ash.Query.sort(name: :asc) |> read!(opts)
  def list_machines!(opts \\ []), do: Machine |> Ash.Query.sort(name: :asc) |> read!(opts)

  def get_machine!(id, opts \\ []) do
    Machine
    |> Ash.Query.filter(id == ^id)
    |> Ash.Query.for_read(:read, %{}, opts)
    |> Ash.read_one!()
  end

  @doc """
  Gets machines based on the scope and ID.
  Returns {:ok, [machine]} on success, {:error, reason} on failure.
  """
  def get_scope_machines(:machine, id) do
    case Machine |> Ash.Query.filter(id == ^id) |> Ash.read!() do
      [] -> {:error, "Machine not found"}
      [machine] -> {:ok, [machine]}
    end
  end

  def get_scope_machines(:line, id) do
    machines =
      Machine
      |> Ash.Query.filter(line_id == ^id)
      |> Ash.Query.sort(name: :asc)
      |> Ash.read!()

    case machines do
      [] -> {:error, "No machines found for line"}
      machines -> {:ok, machines}
    end
  end

  def get_scope_machines(:area, id) do
    machines =
      Machine
      |> Ash.Query.load(:line)
      |> Ash.Query.filter(line.area_id == ^id)
      |> Ash.Query.sort(name: :asc)
      |> Ash.read!()

    case machines do
      [] -> {:error, "No machines found for area"}
      machines -> {:ok, machines}
    end
  end

  def get_scope_machines(:plant, id) do
    machines =
      Machine
      |> Ash.Query.load(line: :area)
      |> Ash.Query.filter(line.area.plant_id == ^id)
      |> Ash.Query.sort(name: :asc)
      |> Ash.read!()

    case machines do
      [] -> {:error, "No machines found for plant"}
      machines -> {:ok, machines}
    end
  end

  @doc """
  Get time trackers for a list of machine IDs within a time period.
  """
  def get_time_trackers(machines, {start_time, end_time}) do
    machine_ids = Enum.map(machines, & &1.id)

    TimeTracker
    |> Ash.Query.filter(machine_id in ^machine_ids)
    |> Ash.Query.filter(start_time >= ^start_time)
    |> Ash.Query.filter(end_time <= ^end_time or is_nil(end_time))
    |> Ash.Query.load(:status)
    |> Ash.read!()
  end

  @doc """
  Gets active production run for machines in a time period.
  Returns the most recent run that overlaps with the time period.
  """
  def get_production_run(machines, {start_time, end_time}) when is_list(machines) do
    machine_ids = Enum.map(machines, & &1.id)

    ProductionRun
    |> Ash.Query.filter(machine_id in ^machine_ids)
    |> Ash.Query.filter(start_time <= ^end_time)
    |> Ash.Query.filter(end_time >= ^start_time or is_nil(end_time))
    |> Ash.Query.sort(start_time: :desc)
    |> Ash.Query.load(:machine)
    |> Ash.Query.limit(1)
    |> Ash.read!()
    |> List.first()
  end

  @doc """
  Convert date range atom to actual start/end times
  """
  def get_time_period(:last_1h) do
    end_time = DateTime.utc_now()
    start_time = DateTime.add(end_time, -1, :hour)
    {start_time, end_time}
  end

  def get_time_period(:last_4h) do
    end_time = DateTime.utc_now()
    start_time = DateTime.add(end_time, -4, :hour)
    {start_time, end_time}
  end

  def get_time_period(:last_8h) do
    end_time = DateTime.utc_now()
    start_time = DateTime.add(end_time, -8, :hour)
    {start_time, end_time}
  end

  def get_time_period(:last_12h) do
    end_time = DateTime.utc_now()
    start_time = DateTime.add(end_time, -12, :hour)
    {start_time, end_time}
  end

  def get_time_period(:last_24h) do
    end_time = DateTime.utc_now()
    start_time = DateTime.add(end_time, -24, :hour)
    {start_time, end_time}
  end

  def get_time_period(:last_7d) do
    end_time = DateTime.utc_now()
    start_time = DateTime.add(end_time, -7, :day)
    {start_time, end_time}
  end

  def get_time_period(:last_30d) do
    end_time = DateTime.utc_now()
    start_time = DateTime.add(end_time, -30, :day)
    {start_time, end_time}
  end

  @doc """
  Calculate OEE metrics for a given scope, ID, and date range.
  Returns {:ok, metrics} or {:error, reason}
  """
  def get_oee_metrics(scope, id, date_range) do
    time_period = get_time_period(date_range)
    {start_time, end_time} = time_period

    with {:ok, machines} <- get_scope_machines(scope, id) do
      trackers = get_time_trackers(machines, time_period)
      run = get_production_run(machines, time_period)
      total_time = DateTime.diff(end_time, start_time, :second) * length(machines)

      metrics = Lemonadechicken.Manufacturing.OEE.calculate_metrics(trackers, total_time, run)
      intervals = Lemonadechicken.Manufacturing.OEE.calculate_interval_metrics(trackers, length(machines), time_period)

      {:ok, %{metrics: metrics, intervals: intervals}}
    end
  end

  # Helper for running Ash actions
  defp read!(query, opts \\ []) do
    query
    |> Ash.Query.for_read(:read, %{}, opts)
    |> Ash.read!()
  end
end
