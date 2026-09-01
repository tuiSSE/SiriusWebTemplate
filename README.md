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
3. Enter the extension metadata.
4. Run `./scripts/install.sh`.
5. Build the main Sirius Web backend with the generated extension installed.

## Placeholder model

The generation script replaces the following placeholders:

- `__GROUP_ID__`
- `__ARTIFACT_ID__`
- `__VERSION__`
- `__PACKAGE_BASE__`
- `__MODEL_PACKAGE__`
- `__SERVICE_PACKAGE__`
- `__MODEL_NAME__`
- `__SERVICE_CLASS__`
- `__ECORE_NS_URI__`

## Notes

This template intentionally keeps the integration flow aligned with the Maven-based Sirius Web starter pattern and does not depend on Docker startup hacks.
