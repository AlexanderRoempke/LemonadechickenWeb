defmodule Lemonadechicken.Manufacturing.Line do
  @moduledoc """
  Represents a production line within a manufacturing area.
  A line contains multiple machines and is where production runs take place.
  """
  use Ash.Resource,
    domain: Lemonadechicken.Manufacturing,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  require Ash.Query

  postgres do
    table "lines"
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
    attribute :active, :boolean, default: true

    timestamps()
  end

  validations do
    validate string_length(:name, min: 2)
    validate string_length(:code, min: 2)
  end

  relationships do
    belongs_to :area, Lemonadechicken.Manufacturing.Area do
      allow_nil? false
      attribute_writable? true
    end

    has_many :machines, Lemonadechicken.Manufacturing.Machine do
      destination_attribute :line_id
    end

    has_many :production_runs, Lemonadechicken.Manufacturing.ProductionRun do
      destination_attribute :line_id
    end
  end

  calculations do
    calculate :machine_count, :integer do
      load :machines
      fn line, _, _ ->
        case line.machines do
          nil -> 0
          machines -> length(machines)
        end
      end
    end

    calculate :active_machines, :integer do
      load :machines
      fn line, _, _ ->
        case line.machines do
          nil -> 0
          machines -> Enum.count(machines, & &1.active)
        end
      end
    end

    calculate :active_run, :struct do
      load :production_runs
      fn line, _, _ ->
        case line.production_runs do
          nil -> nil
          [] -> nil
          runs ->
            runs
            |> Enum.filter(&(&1.status == :in_progress))
            |> List.first()
        end
      end
    end

    calculate :average_efficiency, :float do
      load [production_runs: :machine]
      fn line, _, _ ->
        case line.production_runs do
          nil -> 0.0
          [] -> 0.0
          runs ->
            completed_runs =
              runs
              |> Enum.filter(&(&1.status == :completed))
              |> Enum.map(& &1.efficiency)
              |> Enum.reject(&is_nil/1)

            case completed_runs do
              [] -> 0.0
              efficiencies -> Enum.sum(efficiencies) / length(efficiencies)
            end
        end
      end
    end
  end

  actions do
    defaults [:create, :read, :update, :destroy]

    create :create do
      accept [:name, :code, :description, :area_id]
      argument :area_id, :uuid, allow_nil?: false
    end

    update :update do
      accept [:name, :code, :description, :active]
    end

    read :list do
      prepare build(sort: [name: :asc])
    end

    read :by_area do
      argument :area_id, :uuid, allow_nil?: false
      prepare build(load: [:area])
      filter expr(area_id == ^arg(:area_id))
    end
  end

  code_interface do
    define :create_line, args: [:name, :code, :area_id]
    define :list_lines
    define :get_line, args: [:id]
    define :update_line, args: [:id]
    define :delete_line, args: [:id]
  end

  identities do
    identity :unique_code_per_area, [:area_id, :code]
  end

  policies do
    bypass always() do
      authorize_if always()
    end
  end
end
