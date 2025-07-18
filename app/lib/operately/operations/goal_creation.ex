defmodule Operately.Operations.GoalCreation do
  alias Ecto.Multi
  alias Operately.Repo
  alias Operately.Goals.{Goal, Target}
  alias Operately.Activities
  alias Operately.Access
  alias Operately.Access.{Context, Binding}

  def run(creator, attrs) do
    Multi.new()
    |> insert_goal(creator, attrs)
    |> insert_context()
    |> insert_targets(attrs[:targets] || [])
    |> insert_bindings(creator, attrs)
    |> insert_activity(creator)
    |> Repo.transaction()
    |> Repo.extract_result(:goal)
  end

  defp insert_goal(multi, creator, attrs) do
    Multi.insert(
      multi,
      :goal,
      Goal.changeset(%{
        name: attrs[:name],
        company_id: creator.company_id,
        group_id: attrs[:space_id],
        champion_id: attrs[:champion_id],
        reviewer_id: attrs[:reviewer_id],
        timeframe: attrs[:timeframe],
        parent_goal_id: attrs[:parent_goal_id],
        description: attrs[:description] && Jason.decode!(attrs[:description]),
        creator_id: creator.id,
        next_update_scheduled_at: Operately.Time.first_of_next_month(Date.utc_today())
      })
    )
  end

  defp insert_context(multi) do
    Multi.insert(multi, :context, fn changes ->
      Context.changeset(%{
        goal_id: changes.goal.id
      })
    end)
  end

  defp insert_bindings(multi, creator, attrs) do
    full_access = Access.get_group!(company_id: creator.company_id, tag: :full_access)
    standard = Access.get_group!(company_id: creator.company_id, tag: :standard)
    space_full_access = Access.get_group!(group_id: attrs.space_id, tag: :full_access)
    space_standard = Access.get_group!(group_id: attrs.space_id, tag: :standard)

    multi
    |> Access.maybe_insert_anonymous_binding(creator.company_id, attrs.anonymous_access_level)
    |> Access.insert_binding(:company_full_access_binding, full_access, Binding.full_access())
    |> Access.insert_binding(:company_members_binding, standard, attrs.company_access_level)
    |> Access.insert_binding(:space_full_access_binding, space_full_access, Binding.full_access())
    |> Access.insert_binding(:space_members_binding, space_standard, attrs.space_access_level)
    |> bind_champion(attrs[:champion_id])
    |> bind_reviewer(attrs[:reviewer_id])
  end

  defp bind_champion(multi, champion_id) do
    if champion_id do
      champion_group = Access.get_group!(person_id: champion_id)
      Access.insert_binding(multi, :champion_binding, champion_group, Binding.full_access(), :champion)
    else
      multi
    end
  end

  defp bind_reviewer(multi, reviewer_id) do
    if reviewer_id do
      reviewer_group = Access.get_group!(person_id: reviewer_id)
      Access.insert_binding(multi, :reviewer_binding, reviewer_group, Binding.full_access(), :reviewer)
    else
      multi
    end
  end

  defp insert_activity(multi, creator) do
    Activities.insert_sync(multi, creator.id, :goal_created, fn changes ->
      %{
        company_id: changes.goal.company_id,
        space_id: changes.goal.group_id,
        goal_id: changes.goal.id,
        goal_name: changes.goal.name,
        champion_id: changes.goal.champion_id,
        reviewer_id: changes.goal.reviewer_id,
        creator_id: changes.goal.creator_id,
        new_timeframe: changes.goal.timeframe && Map.from_struct(changes.goal.timeframe)
      }
    end)
  end

  defp insert_targets(multi, targets) do
    targets
    |> Enum.with_index()
    |> Enum.reduce(multi, fn {target, index}, multi ->
      Multi.insert(multi, :"target_#{index}", fn %{goal: goal} ->
        Target.changeset(%{
          goal_id: goal.id,
          name: target[:name],
          from: target[:from],
          to: target[:to],
          value: target[:from],
          unit: target[:unit],
          index: index
        })
      end)
    end)
  end
end
