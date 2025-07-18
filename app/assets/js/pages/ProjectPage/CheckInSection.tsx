import * as Callouts from "@/components/Callouts";
import * as People from "@/models/people";
import * as Projects from "@/models/projects";
import * as React from "react";

import FormattedTime from "@/components/FormattedTime";
import { Avatar } from "turboui";

import { Summary } from "@/components/RichContent";
import { SmallStatusIndicator } from "@/components/status";
import { Link, SecondaryButton } from "turboui";
import { DimmedLabel } from "./Label";

import { usePaths } from "@/routes/paths";
export function CheckInSection({ project }: { project: Projects.Project }) {
  const paths = usePaths();
  return (
    <div className="border-t border-stroke-base py-6">
      <div className="flex items-start gap-4">
        <div className="w-1/5">
          <div className="font-bold text-sm">Check-Ins</div>
          {project.lastCheckIn && (
            <div className="text-sm">
              <Link to={paths.projectCheckInsPath(project.id!)}>View all</Link>
            </div>
          )}
        </div>

        <div className="w-4/5">
          {project.lastCheckIn ? <LastCheckIn project={project} /> : <CheckInZeroState project={project} />}
          <NoReviewerCallout project={project} />
        </div>
      </div>
    </div>
  );
}

function LastCheckIn({ project }) {
  return (
    <div>
      <DimmedLabel>Last Check-In</DimmedLabel>
      <LastCheckInContent project={project} />

      <div className="flex items-start gap-12 mt-6">
        <LastCheckInStatus project={project} />
        <NextCheckIn project={project} />
      </div>

      <div className="mt-6">
        <CheckInNowButton project={project} />
      </div>
    </div>
  );
}

function NextCheckIn({ project }: { project: Projects.Project }) {
  return (
    <div>
      <DimmedLabel>Next Check-In</DimmedLabel>
      <div className="text-sm font-medium">
        Scheduled for <FormattedTime time={project.nextCheckInScheduledAt!} format="relative-weekday-or-date" />
      </div>
    </div>
  );
}

function LastCheckInStatus({ project }: { project: Projects.Project }) {
  const status = project.lastCheckIn!.status!;

  return (
    <div>
      <DimmedLabel>Status</DimmedLabel>
      <div className="flex flex-col gap-1 text-sm">
        <SmallStatusIndicator status={status} />
      </div>
    </div>
  );
}

function LastCheckInContent({ project }: { project: Projects.Project }) {
  const author = project.lastCheckIn!.author!;
  const description = project.lastCheckIn!.description!;
  const avatar = <Avatar person={author} size="tiny" />;

  return (
    <div className="flex items-start gap-2 max-w-xl mt-2">
      <div className="flex flex-col gap-1">
        <div className="font-bold flex items-center gap-1">
          {avatar} {People.shortName(author)} submitted: <LastCheckInLink project={project} />
        </div>

        <Summary jsonContent={description} characterCount={200} />
      </div>
    </div>
  );
}

function LastCheckInLink({ project }: { project: Projects.Project }) {
  const paths = usePaths();
  const time = project.lastCheckIn!.insertedAt!;
  const path = paths.projectCheckInPath(project.lastCheckIn!.id!);

  return (
    <Link to={path} testId="last-check-in-link">
      Check-in <FormattedTime time={time} format="long-date" />
    </Link>
  );
}

function CheckInNowButton({ project }: { project: Projects.Project }) {
  const paths = usePaths();
  if (!project.permissions!.canCheckIn) return null;

  const newCheckInPath = paths.projectCheckInNewPath(project.id!);

  return (
    <div className="flex">
      <SecondaryButton linkTo={newCheckInPath} testId="check-in-now" size="xs">
        Check-In Now
      </SecondaryButton>
    </div>
  );
}

function CheckInZeroState({ project }: { project: Projects.Project }) {
  return (
    <div className="text-sm">
      Asking the champion to check-in every Friday.
      <div className="mt-2">
        <CheckInNowButton project={project} />
      </div>
    </div>
  );
}

function NoReviewerCallout({ project }: { project: Projects.Project }) {
  const paths = usePaths();
  if (project.reviewer) return null;

  const path = paths.projectContributorsAddPath(project.id!, { type: "reviewer" });
  const addReviewer = (
    <Link to={path} testId="add-reviewer">
      Add a Reviewer
    </Link>
  );

  return (
    <div className="mt-4">
      <Callouts.InfoCallout
        testId="no-reviewer-callout"
        message={"Want a second pair of eyes?"}
        description={
          <>
            Check-ins are on, but important updates might slip through the cracks.
            <br />
            {addReviewer} to get feedback and keep things moving smoothly.
          </>
        }
      />
    </div>
  );
}
