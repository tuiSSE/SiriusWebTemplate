#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
GENERATED_DIR="$PROJECT_DIR/generated"

# Ask for the sirius-web location unless already provided via env var
SIRIUS_WEB_ROOT="${SIRIUS_WEB_ROOT:-}"
if [ -z "$SIRIUS_WEB_ROOT" ]; then
  read -rp "Path to your sirius-web checkout: " SIRIUS_WEB_ROOT
fi
SIRIUS_WEB_ROOT="$(cd "$SIRIUS_WEB_ROOT" 2>/dev/null && pwd || true)"

# sirius-web structure has pom.xml in packages/, not at the repo root
if [ -z "$SIRIUS_WEB_ROOT" ] || [ ! -f "$SIRIUS_WEB_ROOT/packages/pom.xml" ]; then
  echo "Error: '$SIRIUS_WEB_ROOT' does not look like a sirius-web checkout (packages/pom.xml not found)."
  exit 1
fi

# Find the latest generated project
LATEST_GENERATED=""
if [ -d "$GENERATED_DIR" ]; then
  LATEST_GENERATED=$(find "$GENERATED_DIR" -maxdepth 1 -type d ! -name ".*" | sort | tail -1)
fi

if [ -z "$LATEST_GENERATED" ] || [ ! -d "$LATEST_GENERATED" ]; then
  echo "Error: No generated backend modules found in $GENERATED_DIR"
  echo "Please run './scripts/generate.sh' first to generate an extension."
  exit 1
fi

GENERATED_BACKEND="$LATEST_GENERATED/backend"
if [ ! -d "$GENERATED_BACKEND" ]; then
  echo "Error: Generated backend directory not found at $GENERATED_BACKEND"
  exit 1
fi

# Reuse the project name/group/version chosen during generate.sh
PROJECT_INFO="$LATEST_GENERATED/.project-info"
if [ ! -f "$PROJECT_INFO" ]; then
  echo "Error: $PROJECT_INFO not found. Please regenerate the project with './scripts/generate.sh'."
  exit 1
fi
# shellcheck disable=SC1090
source "$PROJECT_INFO"

echo "Found generated project: $PROJECT_NAME"
echo "  Location: $GENERATED_BACKEND"
echo ""
echo "Installing: $GROUP_ID:$PROJECT_NAME:$VERSION"
echo ""

# Step 1: Build and install to local Maven repository
echo "Step 1: Building and installing generated modules..."
cd "$GENERATED_BACKEND/.."
mvn -DskipTests clean install
echo "✅ Generated modules installed to local Maven repository"
echo ""

# Step 2: Copy the metamodel modules into their own packages/<PROJECT_NAME>/backend/ folder,
# mirroring how packages/ktest/backend/ hosts ktest-metamodel and ktest-metamodel-edit.
SIRIUS_WEB_PACKAGES="$SIRIUS_WEB_ROOT/packages"
METAMODEL_ROOT="$SIRIUS_WEB_PACKAGES/${PROJECT_NAME}/backend"

echo "Step 2: Copying metamodel modules to Sirius Web..."
echo "  Source: $GENERATED_BACKEND"
echo "  Target: $METAMODEL_ROOT"
echo ""

mkdir -p "$METAMODEL_ROOT"

if [ -d "$GENERATED_BACKEND/${PROJECT_NAME}-metamodel" ]; then
  TARGET_DIR="$METAMODEL_ROOT/${PROJECT_NAME}-metamodel"
  echo "  • Copying ${PROJECT_NAME}-metamodel..."
  rm -rf "$TARGET_DIR" 2>/dev/null || true
  cp -r "$GENERATED_BACKEND/${PROJECT_NAME}-metamodel" "$TARGET_DIR"
fi

if [ -d "$GENERATED_BACKEND/${PROJECT_NAME}-metamodel-edit" ]; then
  TARGET_DIR="$METAMODEL_ROOT/${PROJECT_NAME}-metamodel-edit"
  echo "  • Copying ${PROJECT_NAME}-metamodel-edit..."
  rm -rf "$TARGET_DIR" 2>/dev/null || true
  cp -r "$GENERATED_BACKEND/${PROJECT_NAME}-metamodel-edit" "$TARGET_DIR"
fi

# Root aggregator pom for packages/<PROJECT_NAME>/backend/, same shape as packages/ktest/backend/pom.xml
cat > "$METAMODEL_ROOT/pom.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
	<modelVersion>4.0.0</modelVersion>

	<groupId>${GROUP_ID}</groupId>
	<artifactId>${PROJECT_NAME}-metamodel-root</artifactId>
	<version>${VERSION}</version>

	<name>${PROJECT_NAME}-metamodel-root</name>
	<description>${PROJECT_NAME} Metamodel Root</description>
	<packaging>pom</packaging>

	<modules>
		<module>${PROJECT_NAME}-metamodel</module>
		<module>${PROJECT_NAME}-metamodel-edit</module>
	</modules>
</project>
EOF

echo ""
echo "Step 3: Registering ${PROJECT_NAME}/backend in packages/pom.xml..."

PACKAGES_POM="$SIRIUS_WEB_PACKAGES/pom.xml"
if grep -q "<module>${PROJECT_NAME}/backend</module>" "$PACKAGES_POM"; then
  echo "  ✓ Module ${PROJECT_NAME}/backend already registered."
else
  echo "  • Adding ${PROJECT_NAME}/backend to packages/pom.xml..."
  sed -i "/<module>ktest\/backend<\/module>/a\ \t\t<module>${PROJECT_NAME}/backend</module>" "$PACKAGES_POM"
fi

# Step 4: Copy the starter module into packages/starters/backend/, alongside ktest-starter
SIRIUS_WEB_STARTERS="$SIRIUS_WEB_PACKAGES/starters/backend"
if [ ! -d "$SIRIUS_WEB_STARTERS" ]; then
  echo "Error: sirius-web starters directory not found at $SIRIUS_WEB_STARTERS"
  exit 1
fi

echo ""
echo "Step 4: Copying starter module to Sirius Web..."
echo "  Source: $GENERATED_BACKEND/$PROJECT_NAME"
echo "  Target: $SIRIUS_WEB_STARTERS"
echo ""

if [ -d "$GENERATED_BACKEND/$PROJECT_NAME" ]; then
  TARGET_DIR="$SIRIUS_WEB_STARTERS/${PROJECT_NAME}-starter"
  echo "  • Copying ${PROJECT_NAME} starter..."
  rm -rf "$TARGET_DIR" 2>/dev/null || true
  cp -r "$GENERATED_BACKEND/$PROJECT_NAME" "$TARGET_DIR"
  
  # Update parent pom to use sirius-web-parent
  STARTER_POM="$TARGET_DIR/pom.xml"
  echo "  • Updating starter pom.xml parent reference..."
  
  # Replace parent block using sed (looking for parent block and replacing it)
  sed -i '/<parent>/,/<\/parent>/c\
\	<parent>\
\		<groupId>org.eclipse.sirius</groupId>\
\		<artifactId>sirius-web-parent</artifactId>\
\		<version>2026.7.3</version>\
\		<relativePath>../../../releng/backend/sirius-web-parent</relativePath>\
\	</parent>' "$STARTER_POM"
fi

echo ""
echo "Step 5: Registering starter module in packages/starters/backend/pom.xml..."

STARTER_PARENT_POM="$SIRIUS_WEB_STARTERS/pom.xml"
MODULE_NAME="${PROJECT_NAME}-starter"

# Check if module is already in pom.xml
if grep -q "<module>$MODULE_NAME</module>" "$STARTER_PARENT_POM"; then
  echo "  ✓ Module $MODULE_NAME already registered."
else
  echo "  • Adding $MODULE_NAME to parent pom.xml..."
  # Add the new module after ktest-starter
  sed -i "/<module>ktest-starter<\/module>/a\ \t\t<module>$MODULE_NAME</module>" "$STARTER_PARENT_POM"
fi

echo ""
echo "Step 6: Registering ${PROJECT_NAME} as a dependency of the Sirius Web application..."

SIRIUS_WEB_APP_POM="$SIRIUS_WEB_ROOT/packages/sirius-web/backend/sirius-web/pom.xml"
if [ ! -f "$SIRIUS_WEB_APP_POM" ]; then
  echo "  ⚠ $SIRIUS_WEB_APP_POM not found, skipping. You'll need to add the dependency manually so it ends up on the app's classpath."
elif grep -q "<artifactId>${PROJECT_NAME}</artifactId>" "$SIRIUS_WEB_APP_POM"; then
  echo "  ✓ Dependency on ${PROJECT_NAME} already registered."
else
  echo "  • Adding ${PROJECT_NAME} dependency after ktest-starter..."
  awk -v groupId="org.eclipse.sirius" -v artifactId="${PROJECT_NAME}" -v version="2026.7.3" '
    { print }
    /<artifactId>ktest-starter<\/artifactId>/ { found=1 }
    found && /<\/dependency>/ {
      print "\t\t<dependency>"
      print "\t\t\t<groupId>" groupId "</groupId>"
      print "\t\t\t<artifactId>" artifactId "</artifactId>"
      print "\t\t\t<version>" version "</version>"
      print "\t\t</dependency>"
      found=0
    }
  ' "$SIRIUS_WEB_APP_POM" > "$SIRIUS_WEB_APP_POM.tmp" && mv "$SIRIUS_WEB_APP_POM.tmp" "$SIRIUS_WEB_APP_POM"
fi

echo ""
echo "Step 7: Building the metamodel and starter modules..."
cd "$METAMODEL_ROOT"
mvn -DskipTests clean install
cd "$SIRIUS_WEB_STARTERS"
mvn -DskipTests clean install

echo ""
echo "✅ Installation complete!"
echo ""
echo "The generated starter '$PROJECT_NAME' has been integrated into Sirius Web."
echo ""
echo "Next steps:"
echo "1. Build the full Sirius Web backend:"
echo "   cd $SIRIUS_WEB_ROOT"
echo "   mvn clean package"
echo ""
echo "2. The $PROJECT_NAME extension will be available in your Sirius Web instance."
