package __SERVICE_PACKAGE__;

import java.util.Objects;

import org.eclipse.sirius.components.core.api.IEditingContext;
import org.eclipse.sirius.components.core.api.IEditingContextProcessor;
import org.eclipse.sirius.web.application.UUIDParser;
import org.eclipse.sirius.web.application.editingcontext.EditingContext;
import org.eclipse.sirius.web.domain.boundedcontexts.project.Nature;
import org.eclipse.sirius.web.domain.boundedcontexts.project.services.api.IProjectSearchService;
import org.eclipse.sirius.web.domain.boundedcontexts.projectsemanticdata.ProjectSemanticData;
import org.eclipse.sirius.web.domain.boundedcontexts.projectsemanticdata.services.api.IProjectSemanticDataSearchService;
import org.springframework.data.jdbc.core.mapping.AggregateReference;
import org.springframework.stereotype.Service;

import __MODEL_PACKAGE__.__MODEL_NAME__Package;

@Service
public class __PROJECT_NAME__EditingContextInitializer implements IEditingContextProcessor {

    private final IProjectSearchService projectSearchService;
    private final IProjectSemanticDataSearchService projectSemanticDataSearchService;

    public __PROJECT_NAME__EditingContextInitializer(IProjectSearchService projectSearchService, IProjectSemanticDataSearchService projectSemanticDataSearchService) {
        this.projectSearchService = Objects.requireNonNull(projectSearchService);
        this.projectSemanticDataSearchService = Objects.requireNonNull(projectSemanticDataSearchService);
    }

    @Override
    public void preProcess(IEditingContext editingContext) {
        if (editingContext instanceof EditingContext emfEditingContext) {
            // Register the metamodel package so its types can be resolved/deserialized and selected as domain types.
            emfEditingContext.getDomain().getResourceSet().getPackageRegistry()
                    .put(__MODEL_NAME__Package.eNS_URI, __MODEL_NAME__Package.eINSTANCE);
        }

        var isProjectTemplate = new UUIDParser().parse(editingContext.getId())
                .flatMap(semanticDataId -> this.projectSemanticDataSearchService.findBySemanticDataId(AggregateReference.to(semanticDataId)))
                .map(ProjectSemanticData::getProject)
                .map(AggregateReference::getId)
                .flatMap(this.projectSearchService::findById)
                .filter(project -> project.getNatures().stream()
                        .map(Nature::name)
                        .anyMatch(__PROJECT_NAME__ProjectTemplatesProvider.__PROJECT_NAME___NATURE::equals))
                .isPresent();

        if (isProjectTemplate && editingContext instanceof EditingContext emfEditingContext) {
            // The generated starter is ready to register generated views here.
        }
    }
}
