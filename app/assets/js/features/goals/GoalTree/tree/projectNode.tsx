import * as Spaces from "@/models/spaces";
import * as Time from "@/utils/time";
import * as Timeframes from "@/utils/timeframes";

import { ProjectCheckIn } from "@/api";
import { Project, ProjectRetrospective } from "@/models/projects";
import { assertPresent } from "@/utils/assertions";
import { Node } from "./node";

export class ProjectNode extends Node {
  public project: Project;
  public lastCheckIn: ProjectCheckIn | null | undefined;
  public retrospective: ProjectRetrospective | null | undefined;

  constructor(project: Project) {
    assertPresent(project.space, "space must be present in project");
    assertPresent(project.status, "Project status is required");

    super();

    this.project = project;
    this.parentId = project.goal?.id!;

    this.id = project.id!;
    this.type = "project";
    this.name = project.name!;

    this.champion = project.champion!;
    this.reviewer = project.reviewer!;

    this.spaceId = project.space.id!;
    this.space = project.space as Spaces.Space;

    this.isActive = project.status === "active";
    this.isClosed = project.status === "closed";
    this.isPaused = project.status === "paused";

    this.progress = this.calculateProgress();
    this.lastCheckInDate = Time.parseDate(project.lastCheckIn?.insertedAt);

    this.retrospective = project.retrospective;
    this.lastCheckIn = project.lastCheckIn;
    this.lastCheckInStatus = project.lastCheckIn?.status || "on_track";

    this.startedAt = Time.parseDate(project.startedAt)!;
  }

  activeTimeframe(): Timeframes.Timeframe {
    if (!this.isClosed) {
      return {
        startDate: Time.parseDate(this.project.startedAt),
        endDate: new Date(),
        type: "days",
      };
    } else {
      return {
        startDate: Time.parseDate(this.project.startedAt),
        endDate: Time.parseDate(this.project.closedAt!),
        type: "days",
      };
    }
  }

  linkTo(paths): string {
    return paths.projectPath(this.project!.id!);
  }

  childrenInfoLabel(): string | null {
    return null;
  }

  compareTimeframe(b: Node): number {
    const aTime = Time.parseDate(this.project.deadline);
    const bTime = Time.parseDate((b as ProjectNode).project.deadline);

    return Time.compareAsc(aTime, bTime);
  }

  private calculateProgress(): number {
    assertPresent(this.project.milestones, "milestones must be present in project");

    const completedMilestones = this.project.milestones.filter((m) => m!.status === "done").length;
    const totalMilestones = this.project.milestones.length;

    return (completedMilestones / totalMilestones) * 100;
  }
}
