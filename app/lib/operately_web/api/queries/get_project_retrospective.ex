defmodule OperatelyWeb.Api.Queries.GetProjectRetrospective do
  use TurboConnect.Query
  use OperatelyWeb.Api.Helpers

  alias Operately.Projects.{Permissions, Retrospective}
  alias Operately.Notifications.UnreadNotificationsLoader

  inputs do
    field? :project_id, :string, null: true
    field? :include_author, :boolean, null: true
    field? :include_project, :boolean, null: true
    field? :include_closed_at, :boolean, null: true
    field? :include_permissions, :boolean, null: true
    field? :include_reactions, :boolean, null: true
    field? :include_subscriptions_list, :boolean, null: true
    field? :include_potential_subscribers, :boolean, null: true
    field? :include_unread_notifications, :boolean, null: true
  end

  outputs do
    field? :retrospective, :project_retrospective, null: true
  end

  def call(conn, inputs) do
    Action.new()
    |> run(:me, fn -> find_me(conn) end)
    |> run(:id, fn -> decode_id(inputs.project_id) end)
    |> run(:retrospective, fn ctx -> load(ctx, inputs) end)
    |> run(:check_permissions, fn ctx -> Permissions.check(ctx.retrospective.request_info.access_level, :can_view) end)
    |> run(:serialized, fn ctx -> {:ok, %{retrospective: Serializer.serialize(ctx.retrospective)}} end)
    |> respond()
   end

  defp respond(result) do
    case result do
      {:ok, ctx} -> {:ok, ctx.serialized}
      {:error, :id, _} -> {:error, :bad_request}
      {:error, :message, _} -> {:error, :not_found}
      {:error, :check_permissions, _} -> {:error, :not_found}
      _ -> {:error, :not_found}
    end
  end

  defp load(ctx, inputs) do
    Retrospective.get(ctx.me, project_id: ctx.id, opts: [
      preload: preload(inputs),
      after_load: after_load(inputs, ctx.me),
    ])
  end

  def preload(inputs) do
    Inputs.parse_includes(inputs, [
      include_author: [:author],
      include_project: [:project],
      include_closed_at: [:project],
      include_reactions: [reactions: :person],
      include_subscriptions_list: :subscription_list,
    ])
  end

  def after_load(inputs, person) do
    Inputs.parse_includes(inputs, [
      include_permissions: &Retrospective.set_permissions/1,
      include_potential_subscribers: &Retrospective.load_potential_subscribers/1,
      include_unread_notifications: UnreadNotificationsLoader.load(person),
    ])
  end
end
