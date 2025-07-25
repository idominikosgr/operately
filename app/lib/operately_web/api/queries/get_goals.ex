defmodule OperatelyWeb.Api.Queries.GetGoals do
  use TurboConnect.Query
  use OperatelyWeb.Api.Helpers

  import Operately.Access.Filters, only: [filter_by_view_access: 2]

  alias OperatelyWeb.Api.Serializer
  alias Operately.Goals.Goal

  inputs do
    field? :space_id, :string, null: true

    field? :include_projects, :boolean, null: true
    field? :include_space, :boolean, null: true
    field? :include_last_check_in, :boolean, null: true

    field? :include_champion, :boolean, null: true
    field? :include_reviewer, :boolean, null: true
  end

  outputs do
    field? :goals, list_of(:goal), null: true
  end

  def call(conn, inputs) do
    {:ok, space_id} = decode_id(inputs[:space_id], :allow_nil)
    inputs = Map.put(inputs, :space_id, space_id)

    goals = load(me(conn), inputs)
    output = %{goals: Serializer.serialize(goals, level: :full)}

    {:ok, output}
  end

  defp load(person, inputs) do
    include_filters = extract_include_filters(inputs)

    (from p in Goal, as: :goal, preload: [:parent_goal, :targets])
    |> Goal.scope_space(inputs[:space_id])
    |> Goal.scope_company(person.company_id)
    |> include_requested(include_filters)
    |> filter_by_view_access(person.id)
    |> Repo.all()
  end

  defp include_requested(query, requested) do
    Enum.reduce(requested, query, fn include, q ->
      case include do
        :include_projects -> from p in q, preload: [projects: [:champion, :reviewer]]
        :include_space -> from p in q, preload: [:group]
        :include_champion -> from p in q, preload: [:champion]
        :include_reviewer -> from p in q, preload: [:reviewer]
        :include_last_check_in -> from p in q, preload: [last_update: [:author, [reactions: :person]]]
        _ -> q
      end
    end)
  end
end
