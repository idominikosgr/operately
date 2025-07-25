defmodule Operately.Support.Features.ProfileSteps do
  use Operately.FeatureCase

  import Operately.PeopleFixtures
  import Operately.CompaniesFixtures
  import Operately.GoalsFixtures
  import Operately.ProjectsFixtures

  step :given_a_person_exists_with_manager_reports_and_peers, ctx do
    company = company_fixture()

    manager = person_fixture_with_account(%{company_id: company.id, full_name: "John Coltrane", manager_id: nil})
    person = person_fixture_with_account(%{company_id: company.id, full_name: "Miles Davis", manager_id: manager.id})

    report_1 = person_fixture_with_account(%{company_id: company.id, full_name: "Bill Evans", manager_id: person.id})
    report_2 = person_fixture_with_account(%{company_id: company.id, full_name: "Herbie Hancock", manager_id: person.id})
    report_3 = person_fixture_with_account(%{company_id: company.id, full_name: "Chick Corea", manager_id: person.id})

    peer_1 = person_fixture_with_account(%{company_id: company.id, full_name: "Wayne Shorter", manager_id: manager.id})
    peer_2 = person_fixture_with_account(%{company_id: company.id, full_name: "Joe Zawinul", manager_id: manager.id})

    peers = [peer_1, peer_2]
    reports = [report_1, report_2, report_3]

    Map.merge(ctx, %{person: person, manager: manager, reports: reports, peers: peers, company: company})
  end

  step :visit_profile_page, ctx do
    UI.visit(ctx, Paths.profile_path(ctx.company, ctx.person))
  end

  step :assert_contact_email_visible, ctx do
    UI.assert_text(ctx, ctx.person.email)
  end

  step :assert_manager_visible, ctx do
    UI.assert_text(ctx, ctx.manager.full_name)
  end

  step :assert_reports_visible, ctx do
    Enum.each(ctx.reports, &UI.assert_text(ctx, &1.full_name))
    ctx
  end

  step :assert_peers_visible, ctx do
    Enum.each(ctx.peers, &UI.assert_text(ctx, &1.full_name))
    ctx
  end

  step :click_manager, ctx do
    UI.click(ctx, testid: "person-card-#{OperatelyWeb.Paths.person_id(ctx.manager)}")
  end

  step :assert_on_manager_profile, ctx do
    UI.assert_page(ctx, Paths.profile_path(ctx.company, ctx.manager))
  end

  step :assert_person_listed_as_report_on_manager_profile, ctx do
    UI.assert_text(ctx, ctx.person.full_name)
  end

  step :given_goals_exist_for_person, ctx do
    peer = hd(ctx.peers)

    goal1 = goal_fixture(ctx.person, %{
      company_id: ctx.company.id,
      space_id: ctx.company.company_space_id,
      reviewer_id: peer.id,
      name: "Improve support first response time",
    })

    goal2 = goal_fixture(ctx.person, %{
      company_id: ctx.company.id,
      space_id: ctx.company.company_space_id,
      champion_id: peer.id,
      reviewer_id: ctx.person.id,
      name: "Increase customer satisfaction",
    })

    Map.merge(ctx, %{goals: [goal1, goal2]})
  end

  step :given_projects_exist_for_person, ctx do
    peer = hd(ctx.peers)

    project1 = project_fixture(%{
      company_id: ctx.company.id,
      group_id: ctx.company.company_space_id,
      creator_id: ctx.person.id,
      champion_id: ctx.person.id,
      reviewer_id: peer.id,
      name: "Project 1",
    })

    project2 = project_fixture(%{
      company_id: ctx.company.id,
      group_id: ctx.company.company_space_id,
      creator_id: ctx.person.id,
      champion_id: peer.id,
      reviewer_id: ctx.person.id,
      name: "Project 2",
    })

    Map.merge(ctx, %{projects: [project1, project2]})
  end

  step :click_about_tab, ctx do
    UI.click(ctx, testid: "tab-about")
  end

  step :click_reviewing_tab, ctx do
    UI.click(ctx, testid: "tab-reviewing")
  end

  step :assert_assinged_goals_and_projects_visible, ctx do
    ctx
    |> UI.assert_text(Enum.at(ctx.goals, 0).name)
    |> UI.assert_text(Enum.at(ctx.projects, 0).name)
  end

  step :assert_reviewing_goals_and_projects_visible, ctx do
    ctx
    |> UI.assert_text(Enum.at(ctx.goals, 1).name)
    |> UI.assert_text(Enum.at(ctx.projects, 1).name)
  end

  step :refute_assinged_goals_and_projects_visible, ctx do
    ctx
    |> UI.refute_text(Enum.at(ctx.goals, 0).name)
    |> UI.refute_text(Enum.at(ctx.projects, 0).name)
  end

  step :refute_reviewing_goals_and_projects_visible, ctx do
    ctx
    |> UI.refute_text(Enum.at(ctx.goals, 1).name)
    |> UI.refute_text(Enum.at(ctx.projects, 1).name)
  end
end
