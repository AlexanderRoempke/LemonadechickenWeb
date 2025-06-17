defmodule Lemonadechicken.Manufacturing.Plant do
  @moduledoc """
  Represents a manufacturing plant in the system.
  A plant is the highest level in the manufacturing hierarchy and contains areas.
  """
  use Ash.Resource,
    domain: Lemonadechicken.Manufacturing,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  require Ash.Query

  postgres do
    table "plants"
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
    attribute :location, :string
    attribute :active, :boolean, default: true

    timestamps()
  end

  validations do
    validate string_length(:name, min: 2)
    validate string_length(:code, min: 2)
  end

  relationships do
    has_many :areas, Lemonadechicken.Manufacturing.Area do
      destination_attribute :plant_id
    end
  end

  calculations do
    calculate :area_count, :integer do
      load :areas
      calculation fn plant, _args ->
        case plant.areas do
          nil -> 0
          areas -> length(areas)
        end
      end
    end

    calculate :has_active_runs, :boolean do
      load :areas
      load [areas: [lines: [:production_runs]]]
      calculation fn plant, _args ->
        case plant.areas do
          nil -> false
          areas ->
            Enum.any?(areas, fn area ->
              case area.lines do
                nil -> false
                lines ->
                  Enum.any?(lines, fn line ->
                    case line.production_runs do
                      nil -> false
                      runs -> Enum.any?(runs, & &1.status == :in_progress)
                    end
                  end)
              end
            end)
        end
      end
    end
  end

  aggregates do
    count :total_machines, [:areas, :lines, :machines] do
      join_filter [:areas, :lines], expr(active == true)
      join_filter [:areas, :lines, :machines], expr(active == true)
    end
  end

  actions do
    defaults [:create, :read, :update, :destroy]

    create :create do
      accept [:name, :code, :description, :location]
    end

    update :update do
      accept [:name, :code, :description, :location, :active]
    end

    read :list do
      prepare build(sort: [name: :asc])
    end
  end

  code_interface do
    define :create_plant, args: [:name, :code]
    define :list_plants
    define :get_plant, args: [:id]
    define :update_plant, args: [:id]
    define :delete_plant, args: [:id]
  end

  identities do
    identity :unique_code, [:code]
  end

  policies do
    bypass always() do
      authorize_if always()
    end
  end
end
