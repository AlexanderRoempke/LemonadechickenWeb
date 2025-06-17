defmodule Lemonadechicken.Manufacturing.Area do
  @moduledoc """
  Represents a manufacturing area within a plant.
  An area contains multiple production lines.
  """
  use Ash.Resource,
    domain: Lemonadechicken.Manufacturing,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  require Ash.Query

  postgres do
    table "areas"
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
    belongs_to :plant, Lemonadechicken.Manufacturing.Plant do
      allow_nil? false
      attribute_writable? true
    end

    has_many :lines, Lemonadechicken.Manufacturing.Line do
      destination_attribute :area_id
    end
  end

  calculations do
    calculate :line_count, :integer do
      load :lines
      calculation fn area, _args ->
        case area.lines do
          nil -> 0
          lines -> length(lines)
        end
      end
    end

    calculate :active_run_count, :integer do
      load [lines: :production_runs]
      calculation fn area, _args ->
        case area.lines do
          nil -> 0
          lines ->
            lines
            |> Enum.flat_map(fn line ->
              case line.production_runs do
                nil -> []
                runs -> Enum.filter(runs, & &1.status == :in_progress)
              end
            end)
            |> length()
        end
      end
    end
  end

  aggregates do
    count :total_machines, [:lines, :machines] do
      join_filter :lines, expr(active == true)
      join_filter [:lines, :machines], expr(active == true)
    end
  end

  # Resource actions
  actions do
    defaults [:create, :read, :update, :destroy]

    read :list do
      prepare build(sort: [name: :asc])
    end

    read :by_id do
      argument :id, :uuid, allow_nil?: false
      prepare build(load: [:plant])
      filter expr(id == ^arg(:id))
    end

    read :by_plant do
      argument :plant_id, :uuid, allow_nil?: false
      prepare build(load: [:plant])
      filter expr(plant_id == ^arg(:plant_id))
    end

    create :create do
      accept [:name, :code, :description, :plant_id]
      argument :plant_id, :uuid, allow_nil?: false
    end

    update :update do
      accept [:name, :code, :description, :active]
    end
  end

  identities do
    identity :unique_code_per_plant, [:plant_id, :code]
  end

  policies do
    bypass always() do
      authorize_if always()
    end
  end
end
