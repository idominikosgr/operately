import * as KeyResources from "@/models/keyResources";
import * as Projects from "@/models/projects";
import * as React from "react";

import { useNavigateTo } from "@/routes/useNavigateTo";

import { usePaths } from "@/routes/paths";
interface FormState {
  projectId: string;
  resourceType: string;

  name: string;
  setName: (name: string) => void;

  url: string;
  setUrl: (url: string) => void;

  submit: () => void;
  submitting: boolean;
  isValid: boolean;
}

export function useForm(project: Projects.Project, resourceType: string): FormState {
  const paths = usePaths();
  const gotoResourceList = useNavigateTo(paths.projectEditResourcesPath(project.id!));

  const [name, setName] = React.useState("");
  const [url, setUrl] = React.useState("");

  const isValid = React.useMemo(() => {
    return name.length > 0 && url.length > 0;
  }, [name, url]);

  const [add, { loading }] = KeyResources.useAddKeyResource();

  const submit = React.useCallback(async () => {
    await add({
      projectId: project.id!,
      title: name,
      link: url,
      resourceType,
    });
    gotoResourceList();
  }, [name, url, resourceType]);

  return {
    projectId: project.id!,
    resourceType,

    name,
    setName,
    url,
    setUrl,

    submit,
    submitting: loading,
    isValid,
  };
}
