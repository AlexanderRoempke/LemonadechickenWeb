defmodule Lemonadechicken.Manufacturing.Machine do
  @moduledoc """
  Represents a machine on a production line.
  Machines are the primary units of production and their status is tracked for OEE calculations.
  """
  use Ash.Resource,
    domain: Lemonadechicken.Manufacturing,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "machines"
    repo Lemonadechicken.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
    end

    attribute :code, :string do
      allow_nil? false
    end

    attribute :description, :string
    attribute :model, :string
    attribute :serial_number, :string
    attribute :active, :boolean, default: true

    timestamps()
  end

  validations do
    validate string_length(:name, min: 2)
    validate string_length(:code, min: 2)
  end

  relationships do
    belongs_to :line, Lemonadechicken.Manufacturing.Line do
      allow_nil? false
      attribute_writable? true
    end

    belongs_to :current_status, Lemonadechicken.Manufacturing.MachineStatus do
      attribute_writable? true
    end

    has_many :time_trackers, Lemonadechicken.Manufacturing.TimeTracker do
      destination_attribute :machine_id
    end

    has_many :production_runs, Lemonadechicken.Manufacturing.ProductionRun do
      destination_attribute :machine_id
    end
  end

  calculations do
    calculate :current_status_name, :string do
      load :current_status
      calculation fn machine, _args ->
        case machine.current_status do
          nil -> nil
          status -> status.name
        end
      end
    end

    calculate :current_status_type, :atom do
      load :current_status
      calculation fn machine, _args ->
        case machine.current_status do
          nil -> nil
          status -> status.status_type
        end
      end
    end

    calculate :uptime_percentage, :float do
      argument :start_date, :utc_datetime_usec
      argument :end_date, :utc_datetime_usec
      load [:time_trackers]

      calculation fn machine, args ->
        case {args.start_date, args.end_date} do
          {nil, _} -> 0.0
          {_, nil} -> 0.0
          {start_date, end_date} ->
            total_time = DateTime.diff(end_date, start_date, :second)

            downtime =
              (machine.time_trackers || [])
              |> Enum.filter(fn tracker ->
                DateTime.compare(tracker.start_time, end_date) == :lt &&
                  (is_nil(tracker.end_time) || DateTime.compare(tracker.end_time, start_date) == :gt)
              end)
              |> Enum.reduce(0, fn tracker, acc ->
                end_time = tracker.end_time || DateTime.utc_now()
                # Use case expressions directly for datetime comparisons
                overlap_start = case DateTime.compare(tracker.start_time, start_date) do
                  :gt -> tracker.start_time
                  _ -> start_date
                end
                overlap_end = case DateTime.compare(end_time, end_date) do
                  :lt -> end_time
                  _ -> end_date
                end
                acc + DateTime.diff(overlap_end, overlap_start, :second)
              end)

            case total_time do
              0 -> 0.0
              _ -> ((total_time - downtime) / total_time * 100) |> Float.round(2)
            end
        end
      end
    end

    calculate :latest_production_run, :struct do
      load [:production_runs]
      calculation fn machine, _args ->
        case machine.production_runs do
          nil -> nil
          [] -> nil
          runs ->
            runs
            |> Enum.sort_by(& &1.planned_start_time, {:desc, DateTime})
            |> List.first()
        end
      end
    end
  end

  code_interface do
    define :create_machine, args: [:name, :code, :line_id]
    define :list_machines
    define :get_machine, args: [:id]
    define :update_machine, args: [:id]
    define :change_machine_status, args: [:id, :status_id]
    define :delete_machine, args: [:id]
  end

  # Resource actions
  actions do
    defaults [:create, :read, :update, :destroy]

    create :create do
      accept [:name, :code, :description, :model, :serial_number, :line_id]
      argument :line_id, :uuid, allow_nil?: false
    end

    update :update do
      accept [:name, :code, :description, :model, :serial_number, :active]
    end

    update :change_status do
      accept []
      argument :status_id, :uuid, allow_nil?: false

      validate fn changeset, _context ->
        previous_tracker =
          changeset
          |> Ash.Changeset.get_attribute(:id)
          |> case do
            nil -> nil
            id ->
              Lemonadechicken.Manufacturing.TimeTracker
              |> Ash.Query.filter(machine_id == id and is_nil(end_time))
              |> Ash.Query.sort(start_time: :desc)
              |> Ash.Query.limit(1)
              |> Lemonadechicken.read_one()
          end

        case previous_tracker do
          nil -> :ok
          tracker ->
            Lemonadechicken.Manufacturing.TimeTracker
            |> Ash.Changeset.for_update(:update, tracker)
            |> Ash.Changeset.force_change_attribute(:end_time, DateTime.utc_now())
            |> Lemonadechicken.update()
        end
        :ok
      end

      change set_attribute(:current_status_id, arg(:status_id))

      change fn changeset, _ ->
        Ash.Changeset.after_action(changeset, fn _changeset, machine ->
          # Create a new time tracker when status changes
          Lemonadechicken.Manufacturing.TimeTracker
          |> Ash.Changeset.for_create(:create, %{
            machine_id: machine.id,
            status_id: machine.current_status_id,
            start_time: DateTime.utc_now()
          })
          |> Ash.create!()

          {:ok, machine}
        end)
      end
    end

    read :for_oee_calculation do
      prepare build(
        load: [
          :current_status,
          :time_trackers,
          :production_runs,
          line: [:area]
        ]
      )
    end
  end
end
