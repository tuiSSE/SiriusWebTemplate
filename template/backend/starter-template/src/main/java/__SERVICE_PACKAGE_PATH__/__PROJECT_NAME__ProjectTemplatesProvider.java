package __SERVICE_PACKAGE__;

import java.util.List;

import org.eclipse.sirius.web.application.project.services.api.IProjectTemplateProvider;
import org.eclipse.sirius.web.application.project.services.api.ProjectTemplate;
import org.eclipse.sirius.web.application.project.services.api.ProjectTemplateNature;
import org.springframework.stereotype.Service;

@Service
public class __PROJECT_NAME__ProjectTemplatesProvider implements IProjectTemplateProvider {

    public static final String __PROJECT_NAME___TEMPLATE_ID = "__PROJECT_NAME__-template";

    public static final String __PROJECT_NAME___NATURE = "siriusWeb://nature?kind=__PROJECT_NAME__";

    @Override
    public List<ProjectTemplate> getProjectTemplates() {
        var projectTemplate = new ProjectTemplate(__PROJECT_NAME___TEMPLATE_ID, "__PROJECT_NAME__", "/project-templates/__PROJECT_NAME__-Template.png", List.of(new ProjectTemplateNature(__PROJECT_NAME___NATURE)));
        return List.of(projectTemplate);
    }
}
