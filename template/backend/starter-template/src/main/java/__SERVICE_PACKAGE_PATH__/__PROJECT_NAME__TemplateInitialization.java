package __SERVICE_PACKAGE__;

import java.util.UUID;

import org.eclipse.sirius.components.emf.services.api.IEMFEditingContext;
import org.eclipse.sirius.components.events.ICause;

import jakarta.validation.constraints.NotNull;

public record __PROJECT_NAME__TemplateInitialization(
        @NotNull UUID id,
        @NotNull IEMFEditingContext editingContext,
        @NotNull String templateId,
        @NotNull ICause causedBy) implements ICause {
}
