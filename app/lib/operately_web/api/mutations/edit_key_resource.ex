defmodule OperatelyWeb.Api.Mutations.EditKeyResource do
  use TurboConnect.Mutation
  use OperatelyWeb.Api.Helpers

  alias Operately.Projects
  alias Operately.Projects.{Permissions, KeyResource}

  inputs do
    field? :id, :string, null: true
    field? :title, :string, null: true
    field? :link, :string, null: true
  end

  outputs do
    field? :key_resource, :project_key_resource, null: true
  end

  def call(conn, inputs) do
    Action.new()
    |> run(:me, fn -> find_me(conn) end)
    |> run(:id, fn -> decode_id(inputs.id) end)
    |> run(:resource, fn ctx -> fetch_key_resource(ctx) end)
    |> run(:check_permissions, fn ctx -> Permissions.check(ctx.resource.request_info.access_level, :can_edit_resources) end)
    |> run(:operation, fn ctx -> Projects.update_key_resource(ctx.resource, inputs) end)
    |> run(:serialized, fn ctx -> serialize(ctx.operation) end)
    |> respond()
  end

  def respond(result) do
    case result do
      {:ok, ctx} -> {:ok, ctx.serialized}
      {:error, :id, _} -> {:error, :bad_request}
      {:error, :resource, _} -> {:error, :not_found}
      {:error, :check_permissions, _} -> {:error, :forbidden}
      {:error, :operation, _} -> {:error, :internal_server_error}
      _ -> {:error, :internal_server_error}
    end
  end

  defp fetch_key_resource(ctx) do
    KeyResource.get(ctx.me, id: ctx.id, opts: [preload: :project])
  end

  def serialize(resource) do
    resource = Repo.preload(resource, :project)
    {:ok, %{key_resource: Serializer.serialize(resource)}}
  end
end
