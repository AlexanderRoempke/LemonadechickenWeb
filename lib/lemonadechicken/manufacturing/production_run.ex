defmodule Lemonadechicken.Manufacturing.ProductionRun do
  @moduledoc """
  Represents a production run on a manufacturing line.
  Tracks production details, targets, and actual output.
  """
  use Ash.Resource,
    domain: Lemonadechicken.Manufacturing,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "production_runs"
    repo Lemonadechicken.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :code, :string do
      allow_nil? false
    end

    attribute :description, :string

    attribute :planned_start_time, :utc_datetime_usec do
      allow_nil? false
    end

    attribute :planned_end_time, :utc_datetime_usec do
      allow_nil? false
    end

    attribute :actual_start_time, :utc_datetime_usec
    attribute :actual_end_time, :utc_datetime_usec

    attribute :target_quantity, :integer do
      allow_nil? false
      constraints [min: 1]
    end

    attribute :actual_quantity, :integer do
      default 0
      constraints [min: 0]
    end

    attribute :defect_count, :integer do
      default 0
      constraints [min: 0]
    end

    attribute :status, :atom do
      constraints [one_of: [:planned, :in_progress, :completed, :cancelled]]
      default :planned
      allow_nil? false
    end

    timestamps()
  end

  validations do
    validate string_length(:code, min: 2)

    validate present([:planned_start_time, :planned_end_time, :target_quantity])

    # Custom validation for planned dates
    validate fn changeset, _ ->
      start_time = Ash.Changeset.get_attribute(changeset, :planned_start_time)
      end_time = Ash.Changeset.get_attribute(changeset, :planned_end_time)

      case {start_time, end_time} do
        {nil, _} -> :ok
        {_, nil} -> :ok
        {start_time, end_time} ->
          if DateTime.compare(end_time, start_time) == :gt do
            :ok
          else
            {:error, field: :planned_end_time, message: "Planned end time must be after planned start time"}
          end
      end
    end

    # Custom validation for actual dates
    validate fn changeset, _ ->
      start_time = Ash.Changeset.get_attribute(changeset, :actual_start_time)
      end_time = Ash.Changeset.get_attribute(changeset, :actual_end_time)

      case {start_time, end_time} do
        {_, nil} -> :ok
        {nil, _} -> {:error, field: :actual_start_time, message: "Actual start time is required when setting end time"}
        {start_time, end_time} ->
          if DateTime.compare(end_time, start_time) == :gt do
            :ok
          else
            {:error, field: :actual_end_time, message: "Actual end time must be after actual start time"}
          end
      end
    end
  end

  relationships do
    belongs_to :machine, Lemonadechicken.Manufacturing.Machine do
      allow_nil? false
      attribute_writable? true
    end
  end

  calculations do
    calculate :duration_minutes, :float do
      fn run, _, _ ->
        start_time = run.actual_start_time || run.planned_start_time
        end_time = run.actual_end_time || run.planned_end_time

        case {start_time, end_time} do
          {nil, _} -> 0.0
          {_, nil} -> 0.0
          {start_time, end_time} ->
            DateTime.diff(end_time, start_time, :second) / 60
        end
      end
    end

    calculate :efficiency, :float do
      fn run, _, _ ->
        case run.actual_quantity do
          nil -> 0.0
          0 -> 0.0
          actual ->
            case {run.actual_start_time, run.actual_end_time} do
              {nil, _} -> 0.0
              {_, nil} -> 0.0
              {start_time, end_time} ->
                actual_minutes = DateTime.diff(end_time, start_time, :second) / 60
                planned_minutes = DateTime.diff(run.planned_end_time, run.planned_start_time, :second) / 60
                planned_rate = run.target_quantity / max(planned_minutes, 1)
                actual_rate = actual / max(actual_minutes, 1)
                (actual_rate / planned_rate * 100) |> Float.round(2)
            end
        end
      end
    end

    calculate :quality_rate, :float do
      fn run, _, _ ->
        case run do
          %{actual_quantity: nil} -> 0.0
          %{actual_quantity: 0} -> 0.0
          %{actual_quantity: actual, defect_count: defect_count} ->
            good_parts = actual - (defect_count || 0)
            (good_parts / actual * 100) |> Float.round(2)
        end
      end
    end
  end

  code_interface do
    define :create_run, args: [:machine_id, :code, :planned_start_time, :planned_end_time, :target_quantity]
    define :list_runs, args: []
    define :get_run, args: [:id]
    define :update_run, args: [:id]
    define :start_run, args: [:id]
    define :end_run, args: [:id]
    define :cancel_run, args: [:id]
  end

  actions do
    defaults [:create, :read, :update, :destroy]

    create :create do
      accept [:code, :description, :planned_start_time, :planned_end_time, :target_quantity, :machine_id]
      argument :machine_id, :uuid, allow_nil?: false
    end

    update :update do
      accept [:code, :description, :planned_start_time, :planned_end_time, :target_quantity, :actual_quantity, :defect_count]
    end

    update :start_run do
      accept []

      change fn changeset, _ ->
        now = DateTime.utc_now()
        changeset
        |> Ash.Changeset.change_attribute(:actual_start_time, now)
        |> Ash.Changeset.change_attribute(:status, :in_progress)
      end
    end

    update :end_run do
      accept []

      change fn changeset, _ ->
        now = DateTime.utc_now()
        changeset
        |> Ash.Changeset.change_attribute(:actual_end_time, now)
        |> Ash.Changeset.change_attribute(:status, :completed)
      end
    end

    update :cancel_run do
      accept []
      change set_attribute(:status, :cancelled)
    end

    update :update_quantities do
      accept [:actual_quantity, :defect_count]
    end

    read :get_active_run do
      argument :machine_id, :uuid, allow_nil?: false
      filter expr(machine_id == ^arg(:machine_id) and status == :in_progress)
    end

    read :list_active_runs do
      filter expr(status == :in_progress)
    end
  end
end
