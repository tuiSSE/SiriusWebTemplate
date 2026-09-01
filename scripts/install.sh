#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_DIR"
echo "Installing generated extension into the local Maven repository..."
mvn -DskipTests install

echo "Done. The generated extension is ready to be added as a Maven dependency to your Sirius Web backend."
