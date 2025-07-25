defmodule OperatelyWeb.Api.Queries.GetCompany do
  use TurboConnect.Query
  use OperatelyWeb.Api.Helpers

  alias OperatelyWeb.Api.Serializer
  alias Operately.Companies.Company

  require Logger

  inputs do
    field? :id, :company_id, null: true

    field? :include_permissions, :boolean, null: true
    field? :include_people, :boolean, null: true
    field? :include_admins, :boolean, null: true
    field? :include_owners, :boolean, null: true
    field? :include_general_space, :boolean, null: true
  end

  outputs do
    field? :company, :company, null: true
  end

  def call(conn, inputs) do
    Company.get(me(conn),
      short_id: inputs.id,
      opts: [
        after_load: after_load_hooks(inputs)
      ]
    )
    |> case do
      {:ok, company} -> {:ok, serialize(company)}
      {:error, :not_found} -> {:error, :not_found}
      e -> internal_server_error(e)
    end
  end

  def after_load_hooks(inputs) do
    Inputs.parse_includes(inputs,
      include_people: &Company.load_people/1,
      include_admins: &Company.load_admins/1,
      include_owners: &Company.load_owners/1,
      include_permissions: &Company.load_permissions/1,
      include_general_space: &Company.load_general_space/1
    )
  end

  defp internal_server_error(e) do
    Logger.error("Failed to get company: #{inspect(e)}")
    {:error, :internal_server_error}
  end

  defp serialize(company) do
    %{company: Serializer.serialize(company, level: :full)}
  end
end
