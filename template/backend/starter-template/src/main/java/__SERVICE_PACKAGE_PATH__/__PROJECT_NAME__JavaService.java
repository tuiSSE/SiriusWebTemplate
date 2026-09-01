package __SERVICE_PACKAGE__;

import java.util.Random;

import org.eclipse.emf.ecore.EObject;

public class __PROJECT_NAME__JavaService {

    public int randomNumber(EObject self) {
        return new Random().nextInt(100);
    }

    public String randomNumberAsString(EObject self) {
        return String.valueOf(this.randomNumber(self));
    }

    public String helloWorld(EObject self) {
        return "Hello World";
    }
}
