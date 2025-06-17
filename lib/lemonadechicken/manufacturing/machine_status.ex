defmodule Lemonadechicken.Manufacturing.MachineStatus do
  @moduledoc """
  Defines possible machine statuses and their types.
  Used to track different states a machine can be in (running, stopped, maintenance, etc.).
  """
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshCodeInterface]

  require Ash.Query

  postgres do
    table "machine_statuses"
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

    attribute :status_type, :atom do
      constraints [one_of: [:running, :idle, :down, :maintenance, :setup]]
      allow_nil? false
      default :idle
    end

    attribute :color, :string do
      constraints [match: ~r/^#[0-9A-Fa-f]{6}$/]
      default "#808080"
    end

    attribute :active, :boolean, default: true

    timestamps()
  end

  validations do
    validate string_length(:name, min: 2)
    validate string_length(:code, min: 2)
  end

  relationships do
    has_many :machines, Lemonadechicken.Manufacturing.Machine do
      destination_attribute :current_status_id
    end

    has_many :time_trackers, Lemonadechicken.Manufacturing.TimeTracker do
      destination_attribute :status_id
    end
  end

  code_interface do
    define :get_by_code, args: [:code]
    define :list_active, args: []
  end

  actions do
    defaults [:create, :read, :update, :destroy]

    create :create do
      accept [:name, :code, :description, :status_type, :color]
    end

    update :update do
      accept [:name, :code, :description, :status_type, :color, :active]
    end

    read :list do
      prepare build(sort: [name: :asc])
    end

    read :by_code do
      argument :code, :string, allow_nil?: false
      prepare build(sort: [name: :asc])
      filter expr(code == ^arg(:code))
    end

    read :list_active do
      prepare build(sort: [name: :asc])
      filter expr(active == true)
    end
  end
end
