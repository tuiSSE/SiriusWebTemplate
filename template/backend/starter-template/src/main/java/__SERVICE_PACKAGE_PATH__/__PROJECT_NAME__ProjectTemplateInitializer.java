package __SERVICE_PACKAGE__;

import java.util.Objects;
import java.util.UUID;

import org.eclipse.sirius.components.core.api.IEditingContext;
import org.eclipse.sirius.components.core.api.IEditingContextPersistenceService;
import org.eclipse.sirius.components.emf.ResourceMetadataAdapter;
import org.eclipse.sirius.components.emf.services.JSONResourceFactory;
import org.eclipse.sirius.components.emf.services.api.IEMFEditingContext;
import org.eclipse.sirius.components.events.ICause;
import org.eclipse.sirius.web.application.project.services.api.ISemanticDataInitializer;
import org.springframework.stereotype.Service;

import __MODEL_PACKAGE__.*;

@Service
public class __PROJECT_NAME__ProjectTemplateInitializer implements ISemanticDataInitializer {
    private final IEditingContextPersistenceService editingContextPersistenceService;

    public __PROJECT_NAME__ProjectTemplateInitializer(IEditingContextPersistenceService editingContextPersistenceService) {
        this.editingContextPersistenceService = Objects.requireNonNull(editingContextPersistenceService);
    }

    @Override
    public boolean canHandle(String projectTemplateId) {
        return __PROJECT_NAME__ProjectTemplatesProvider.__PROJECT_NAME___TEMPLATE_ID.equals(projectTemplateId);
    }

    @Override
    public void handle(ICause cause, IEditingContext editingContext, String projectTemplateId) {
        if (__PROJECT_NAME__ProjectTemplatesProvider.__PROJECT_NAME___TEMPLATE_ID.equals(projectTemplateId)
                && editingContext instanceof IEMFEditingContext emfEditingContext) {
            var resource = new JSONResourceFactory().createResourceFromPath(UUID.randomUUID().toString());
            resource.eAdapters().add(new ResourceMetadataAdapter("__PROJECT_NAME__"));
            emfEditingContext.getDomain().getResourceSet().getResources().add(resource);
            resource.getContents().add(__MODEL_NAME__Factory.eINSTANCE.create__MODEL_NAME__());
            this.editingContextPersistenceService.persist(cause, editingContext);
        }
    }
}
