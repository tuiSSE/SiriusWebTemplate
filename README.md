# Sirius Web Extension Template

This repository is the starting point for a custom Sirius Web extension based on an EMF `.ecore` model and a Java AQL service.

## Goal

The generated project follows the same integration pattern as the built-in Sirius Web starter modules:

- a Maven module for the extension
- Spring auto-configuration discovery
- an `IJavaServiceProvider` implementation
- Java service methods exposed to the AQL interpreter
- an `.ecore` model that can be renamed and customized

## Repository workflow

1. Fork this template.
2. Run `./scripts/generate.sh`.
3. Enter the extension metadata (Project Name, Group ID, Version).
4. Open the generated project in Eclipse.
5. Generate Java classes from the EMF model using the included `.genmodel` file.
6. Run `./scripts/install.sh`.
7. Build the main Sirius Web backend with the generated extension installed.

## Generating Java classes from the EMF model

After running `./scripts/generate.sh`, the generated project includes:

- An Eclipse `.project` file (configured with Maven and Sirius nature)
- A `.classpath` file (Maven/PDE configuration for JRE 21)
- An `.ecore` model file (your custom EMF metamodel)
- A `.genmodel` file (pre-configured EMF generator model for Maven layout)
- `pom.xml` files (Maven project structure)

### Steps to generate the metamodel Java classes:

1. **Import the project in Eclipse:**
   ```bash
   cd generated/<PROJECT_NAME>/backend/<PROJECT_NAME>-metamodel
   ```
   In Eclipse: File → Import → Existing Projects into Workspace, select the folder above.

2. **Generate the metamodel code:**
   - In the Model Explorer, right-click `<MODEL_NAME>.genmodel`
   - Select "Generate Model Code"
   - The generated Java classes are created in `src/main/java/<package>/model/`
   - Generated edit classes appear in a new `<PROJECT_NAME>-metamodel-edit` module

3. **The generation creates:**
   - `<PROJECT_NAME>-metamodel/src/main/java/<package>/model/` — Metamodel classes (ECore model as Java)
   - `<PROJECT_NAME>-metamodel-edit/src/main/java/<package>/model/provider/` — Edit support (display names, icons, etc.)

Both modules are Maven projects with proper `pom.xml` files ready for integration with Sirius Web.

**Note:** The `.genmodel` file is pre-configured with Maven directories (`src/main/java` instead of `src`) and proper package settings. You can customize the model in the `.ecore` file, and EMF will regenerate the Java classes accordingly.

## Placeholder variables

The generation script replaces the following placeholders throughout the template:

| Placeholder | Description | Example |
|---|---|---|
| `__PROJECT_NAME__` | The project name (with original casing) | `myTest` |
| `__GROUP_ID__` | The group ID (reverse domain format) | `example.com` |
| `__VERSION__` | The Maven version | `0.0.1-SNAPSHOT` |
| `__PROJECT_IDENTITY__` | Alphanumeric project name (used for package) | `mytest` |
| `__PACKAGE_BASE__` | Base package name (GROUP_ID + PROJECT_IDENTITY) | `example.com.mytest` |
| `__MODEL_PACKAGE__` | Package for generated model classes | `example.com.mytest.model` |
| `__SERVICE_PACKAGE__` | Package for Java AQL services | `example.com.mytest.services` |
| `__MODEL_NAME__` | Capitalized model name | `MyTest` |
| `__SERVICE_CLASS__` | Service class name | `MyTestService` |
| `__ECORE_NS_URI__` | EMF namespace URI | `http://www.example.com/myTest` |

All directory names and class names in the generated project are derived from the `Project Name` you enter during generation.

## Notes

This template intentionally keeps the integration flow aligned with the Maven-based Sirius Web starter pattern and does not depend on Docker startup hacks.
