defmodule Lemonadechicken.Manufacturing.TimeTracker do
  @moduledoc """
  Tracks machine status changes over time.
  Used for calculating OEE and analyzing machine performance.
  """
  use Ash.Resource,
    domain: Lemonadechicken.Manufacturing,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "time_trackers"
    repo Lemonadechicken.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :start_time, :utc_datetime_usec do
      allow_nil? false
    end

    attribute :end_time, :utc_datetime_usec
    attribute :notes, :string

    timestamps()
  end

  validations do
    # Custom validation for end time being after start time
    validate fn changeset, _ ->
      case {Ash.Changeset.get_attribute(changeset, :start_time),
            Ash.Changeset.get_attribute(changeset, :end_time)} do
        {start_time, nil} -> :ok
        {start_time, end_time} ->
          if DateTime.compare(end_time, start_time) == :gt do
            :ok
          else
            {:error, field: :end_time, message: "End time must be after start time"}
          end
      end
    end
  end

  relationships do
    belongs_to :machine, Lemonadechicken.Manufacturing.Machine do
      allow_nil? false
      attribute_writable? true
    end

    belongs_to :status, Lemonadechicken.Manufacturing.MachineStatus do
      allow_nil? false
      attribute_writable? true
    end

    belongs_to :production_run, Lemonadechicken.Manufacturing.ProductionRun do
      attribute_writable? true
    end
  end

  calculations do
    calculate :duration_minutes, :float do
      fn tracker, _, _ ->
        end_time = tracker.end_time || DateTime.utc_now()
        DateTime.diff(end_time, tracker.start_time, :second) / 60.0
      end
    end

    calculate :is_active, :boolean, expr(is_nil(end_time))
  end

  code_interface do
    define :create_tracker, args: [:machine_id, :status_id, :production_run_id]
    define :list_trackers, args: []
    define :get_tracker, args: [:id]
    define :update_tracker, args: [:id]
    define :delete_tracker, args: [:id]
    define :start_downtime, args: [:id, :status_id]
    define :end_downtime, args: [:id]
  end

  actions do
    defaults [:create, :read, :update, :destroy]

    create :create do
      accept [:machine_id, :status_id, :production_run_id, :start_time, :notes]
      validate present([:machine_id, :status_id, :start_time])
    end

    update :update do
      accept [:end_time, :notes]
    end

    update :start_downtime do
      accept []
      argument :status_id, :uuid
      argument :notes, :string, allow_nil?: true

      validate present(:status_id)

      change set_attribute(:start_time, expr(now()))
      change set_attribute(:status_id, arg(:status_id))
      change set_attribute(:notes, arg(:notes))
    end

    update :end_downtime do
      accept []
      argument :notes, :string, allow_nil?: true

      change set_attribute(:end_time, expr(now()))
      change fn changeset, _ ->
        case Ash.Changeset.get_argument(changeset, :notes) do
          nil -> changeset
          notes -> Ash.Changeset.change_attribute(changeset, :notes, notes)
        end
      end
    end
  end

  policies do
    bypass always() do
      authorize_if always()
    end
  end
end
