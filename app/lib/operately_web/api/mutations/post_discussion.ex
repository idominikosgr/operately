defmodule OperatelyWeb.Api.Mutations.PostDiscussion do
  use TurboConnect.Mutation
  use OperatelyWeb.Api.Helpers

  alias Operately.Groups
  alias Operately.Groups.Permissions
  alias Operately.Operations.DiscussionPosting

  inputs do
    field? :space_id, :id, null: true
    field? :title, :string, null: true
    field? :body, :string, null: true
    field? :post_as_draft, :boolean, null: true

    field? :send_notifications_to_everyone, :boolean, null: true
    field? :subscriber_ids, list_of(:id), null: true
  end

  outputs do
    field? :discussion, :discussion, null: true
  end

  def call(conn, inputs) do
    Action.new()
    |> run(:me, fn -> find_me(conn) end)
    |> run(:attrs, fn -> parse_inputs(inputs) end)
    |> run(:space, fn ctx -> Groups.get_group_with_access_level(ctx.attrs.space_id, ctx.me.id) end)
    |> run(:check_permissions, fn ctx -> Permissions.check(ctx.space.requester_access_level, :can_post_discussions) end)
    |> run(:operation, fn ctx -> DiscussionPosting.run(ctx.me, ctx.space, ctx.attrs) end)
    |> run(:serialized, fn ctx -> {:ok, %{discussion: Serializer.serialize(ctx.operation, level: :essential)}} end)
    |> respond()
  end

  defp respond(result) do
    case result do
      {:ok, ctx} -> {:ok, ctx.serialized}
      {:error, :space_id, _} -> {:error, :bad_request}
      {:error, :space, _} -> {:error, :not_found}
      {:error, :check_permissions, _} -> {:error, :forbidden}
      {:error, :operation, _} -> {:error, :internal_server_error}
      _ -> {:error, :internal_server_error}
    end
  end

  defp parse_inputs(inputs) do
    board_id = fetch_board_id(inputs.space_id)

    {:ok, %{
      messages_board_id: board_id,
      space_id: inputs.space_id,
      title: inputs.title,
      content: Jason.decode!(inputs.body),
      post_as_draft: inputs[:post_as_draft] || false,
      send_to_everyone: inputs[:send_notifications_to_everyone] || false,
      subscription_parent_type: :message,
      subscriber_ids: inputs[:subscriber_ids] || []
    }}
  end

  # This is a temporary function.
  # Once the Space Tools and Messages Boards are fully implemented,
  # the messages_board_id will come from the frontend
  defp fetch_board_id(space_id) do
    from(b in Operately.Messages.MessagesBoard, where: b.space_id == ^space_id, select: b.id) |> Repo.one!()
  end
end
