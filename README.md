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
2. Run `./scripts/generate.sh` to create your extension structure.
3. Enter the extension metadata (Project Name, Group ID, Version).
4. Open the generated project in Eclipse.
5. Generate Java classes from the EMF model using the included `.genmodel` file (see below).
6. Implement your custom Java AQL services in the starter module.
7. Run `./scripts/install.sh` to copy modules to Sirius Web and build them.
8. Build the full Sirius Web backend to include your extension.

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

## Installing the extension into Sirius Web

Once you've generated your extension and (optionally) customized the EMF model, integrate it into Sirius Web:

### Prerequisites
- Sirius Web must be checked out locally
- Maven 3.9+ must be installed

### Installation steps

The `./scripts/install.sh` script automates the integration:

```bash
cd /path/to/generated/project
./scripts/install.sh
```

The script prompts for the path to your sirius-web checkout (or set `SIRIUS_WEB_ROOT` beforehand to skip the prompt), then:
1. Reads the project name/group/version from `.project-info` (written by `generate.sh`)
2. Builds the generated modules and installs them to your local Maven repository (`.m2/repository/`)
3. Copies `<PROJECT_NAME>-metamodel` and `<PROJECT_NAME>-metamodel-edit` to `sirius-web/packages/<PROJECT_NAME>/backend/` (same layout as `packages/ktest/backend/`), generating an aggregator `pom.xml`
4. Registers `<PROJECT_NAME>/backend` in `sirius-web/packages/pom.xml`
5. Copies the starter module to `sirius-web/packages/starters/backend/<PROJECT_NAME>-starter` and updates its parent `pom.xml` to reference `sirius-web-parent`
6. Registers the starter module in `sirius-web/packages/starters/backend/pom.xml`
7. Builds both the metamodel root and the starters module to verify integration

To skip the interactive prompt, set the path beforehand:
```bash
export SIRIUS_WEB_ROOT=/path/to/sirius-web
./scripts/install.sh
```

### Building and running Sirius Web with your extension

After `install.sh` completes:

```bash
cd /path/to/sirius-web
mvn -DskipTests clean package
./docker-compose up  # or use your preferred launch method
```

Your custom extension will now be loaded by Sirius Web on startup through Spring's auto-discovery mechanism.

## Placeholder variables

The generation script replaces the following placeholders throughout the template:

| Placeholder | Description | Example |
|---|---|---|
| `__PROJECT_NAME__` | The project name (with original casing) | `myTest` |
| `__GROUP_ID__` | The group ID (reverse domain format) | `example.com` |
| `__VERSION__` | The Maven version | `0.0.1-SNAPSHOT` |
| `__PROJECT_IDENTITY__` | Alphanumeric project name (used for package) | `mytest` |
| `__PACKAGE_BASE__` | Base package name (GROUP_ID + PROJECT_IDENTITY) | `example.com.mytest` |
| `__ECORE_PACKAGE_NAME__` | Lowercase ecore package name (becomes the domain namespace, e.g. `mytest::MyTestModel`) | `mytest` |
| `__MODEL_PACKAGE__` | Package for generated model classes (equals PACKAGE_BASE) | `example.com.mytest` |
| `__SERVICE_PACKAGE__` | Package for Java AQL services | `example.com.mytest.services` |
| `__MODEL_NAME__` | Capitalized model name | `MyTest` |
| `__SERVICE_CLASS__` | Service class name | `MyTestService` |
| `__ECORE_NS_URI__` | EMF namespace URI | `http://www.example.com/myTest` |

All directory names and class names in the generated project are derived from the `Project Name` you enter during generation.

## Generated project structure

After running `generate.sh`, your extension has this layout:

```
generated/<PROJECT_NAME>/
├── backend/
│   ├── pom.xml                          (Parent for all modules)
│   ├── <PROJECT_NAME>/                  (Starter module with Spring services)
│   │   ├── pom.xml
│   │   ├── .project
│   │   └── src/main/java/
│   │       └── <PACKAGE_BASE>/services/
│   │           ├── <PROJECT_NAME>JavaService.java      (AQL service methods)
│   │           └── <PROJECT_NAME>JavaServiceProvider.java (Spring @Service)
│   ├── <PROJECT_NAME>-metamodel/        (EMF metamodel module)
│   │   ├── pom.xml
│   │   ├── .project
│   │   ├── .classpath
│   │   ├── model/
│   │   │   └── <MODEL_NAME>.ecore       (Your EMF model definition)
│   │   │   └── <MODEL_NAME>.genmodel    (EMF generator config)
│   │   └── src/main/java/               (Generated by EMF)
│   │       └── <MODEL_PACKAGE>/         (Generated model classes)
│   └── <PROJECT_NAME>-metamodel-edit/   (Edit/display support, generated by EMF)
│       ├── pom.xml
│       ├── .project
│       └── src/main/java/
│           └── <MODEL_PACKAGE>/provider/
│
└── .git/ + other standard template files
```

### Spring service discovery

The starter module contains `@Service` classes that Sirius Web auto-discovers via Spring:

- `<PROJECT_NAME>JavaServiceProvider` — implements `IJavaServiceProvider`, returns service classes
- `<PROJECT_NAME>JavaService` — implements your AQL service methods
- Additional initializers for project templates and model initialization (optional)

When Sirius Web starts, Spring loads all `@Service` beans, and the AQL interpreter has access to your custom Java methods.

### EMF model and code generation

The `<PROJECT_NAME>-metamodel` module contains your `.ecore` and `.genmodel` files:

1. Edit `<MODEL_NAME>.ecore` to define your metamodel structure
2. Right-click `<MODEL_NAME>.genmodel` in Eclipse → "Generate Model Code"
3. EMF generates `<PROJECT_NAME>-metamodel/src/main/java/<MODEL_PACKAGE>/`
4. EMF also creates `<PROJECT_NAME>-metamodel-edit/` with editor support classes

The ecore package's `name` is set to the lowercase project identity (not a generic `model` segment), so the domain namespace shown in Sirius Web's type selection dialogs is `<project-identity>::<ClassName>` (e.g. `mytest3::MyTest3Model`), matching the convention used by `ktest`/`flow`.

Both generated modules are Maven projects, so they integrate seamlessly with Sirius Web's build.

## Notes

This template intentionally keeps the integration flow aligned with the Maven-based Sirius Web starter pattern and does not depend on Docker startup hacks.
