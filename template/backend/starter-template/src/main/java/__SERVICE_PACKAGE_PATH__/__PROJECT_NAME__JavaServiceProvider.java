package __SERVICE_PACKAGE__;

import java.util.List;

import org.eclipse.sirius.components.view.View;
import org.eclipse.sirius.components.view.emf.IJavaServiceProvider;
import org.springframework.stereotype.Service;

@Service
public class __PROJECT_NAME__JavaServiceProvider implements IJavaServiceProvider {

    @Override
    public List<Class<?>> getServiceClasses(View view) {
        return List.of(__PROJECT_NAME__JavaService.class);
    }
}
