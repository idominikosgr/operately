defmodule OperatelyWeb.Api.Mutations.CloseProject do
  use TurboConnect.Mutation
  use OperatelyWeb.Api.Helpers

  alias Operately.Projects.{Project, Permissions}
  alias Operately.Operations.ProjectClosed

  inputs do
    field :project_id, :id
    field :retrospective, :string
    field :success_status, :string
    field? :send_notifications_to_everyone, :boolean
    field? :subscriber_ids, list_of(:id)
  end

  outputs do
    field :retrospective, :project_retrospective
  end

  def call(conn, inputs) do
    Action.new()
    |> run(:me, fn -> find_me(conn) end)
    |> run(:attrs, fn -> parse_inputs(inputs) end)
    |> run(:project, fn ctx -> Project.get(ctx.me, id: ctx.attrs.project_id) end)
    |> run(:check_permissions, fn ctx -> Permissions.check(ctx.project.request_info.access_level, :can_close) end)
    |> run(:operation, fn ctx -> ProjectClosed.run(ctx.me, ctx.project, ctx.attrs) end)
    |> run(:serialized, fn ctx -> {:ok, %{retrospective: Serializer.serialize(ctx.operation)}} end)
    |> respond()
  end

  def respond(result) do
    case result do
      {:ok, ctx} -> {:ok, ctx.serialized}
      {:error, :attrs, _} -> {:error, :bad_request}
      {:error, :project, _} -> {:error, :not_found}
      {:error, :check_permissions, _} -> {:error, :forbidden}
      {:error, :operation, _} -> {:error, :internal_server_error}
      _ -> {:error, :internal_server_error}
    end
  end

  defp parse_inputs(inputs) do
    {:ok, %{
      project_id: inputs.project_id,
      content: Jason.decode!(inputs.retrospective),
      success_status: String.to_atom(inputs.success_status),
      send_to_everyone: inputs[:send_notifications_to_everyone] || false,
      subscription_parent_type: :project_retrospective,
      subscriber_ids: inputs[:subscriber_ids] || []
    }}
  end
end
