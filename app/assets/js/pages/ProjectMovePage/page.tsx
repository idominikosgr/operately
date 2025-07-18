import * as Pages from "@/components/Pages";
import * as Paper from "@/components/PaperContainer";
import * as Spaces from "@/models/spaces";
import * as React from "react";

import * as Projects from "@/models/projects";

import { ProjectPageNavigation } from "@/components/ProjectPageNavigation";
import { SpaceCard, SpaceCardGrid } from "@/features/spaces/SpaceCards";
import { compareIds } from "@/routes/paths";
import { useNavigateTo } from "@/routes/useNavigateTo";
import { useLoadedData } from "./loader";

import { usePaths } from "@/routes/paths";
export function Page() {
  const { project, spaces } = useLoadedData();

  const candidateSpaces = spaces.filter((space) => !compareIds(space.id!, project.space?.id!));

  return (
    <Pages.Page title={["Move to another space", project.name!]}>
      <Paper.Root size="small">
        <ProjectPageNavigation project={project} />

        <Paper.Body>
          <div className="text-content-accent text-3xl font-extrabold text-center">Moving to another space</div>

          {candidateSpaces.length === 0 ? (
            <NoOtherSpaces />
          ) : (
            <MoveToSpace project={project} candidateSpaces={candidateSpaces} />
          )}
        </Paper.Body>
      </Paper.Root>
    </Pages.Page>
  );
}

function NoOtherSpaces() {
  return (
    <div className="uppercase text-content-dimmed text-sm font-medium mt-4 tracking-wide">
      There are no other spaces to move this project to
    </div>
  );
}

function MoveToSpace({ project, candidateSpaces }: { project: Projects.Project; candidateSpaces: Spaces.Space[] }) {
  const paths = usePaths();
  const gotoProject = useNavigateTo(paths.projectPath(project.id!));
  const [move] = Projects.useMoveProjectToSpace();

  const moveProjectToSpace = async (project: Projects.Project, space: Spaces.Space) => {
    await move({ projectId: project.id, spaceId: space.id! });
    gotoProject();
  };

  return (
    <>
      <div className="uppercase text-content-dimmed text-sm font-medium mt-8 mb-4 tracking-wide text-center">
        Select a destination space
      </div>

      <SpaceCardGrid>
        {candidateSpaces.map((space) => (
          <SpaceCard
            key={space.id!}
            space={space}
            testId={`space-${space.id}`}
            onClick={() => moveProjectToSpace(project, space)}
          />
        ))}
      </SpaceCardGrid>
    </>
  );
}
