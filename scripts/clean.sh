#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
GENERATED_DIR="$PROJECT_DIR/generated"
GENERATION_INFO="$GENERATED_DIR/.generation-info"

usage() {
  cat << EOF
Usage: $0 [PROJECT_NAME ...] [--all] [--no-uninstall] [--yes]

Removes stale generated extensions under generated/ so install.sh can no longer
pick the wrong project by accident. Also undoes install.sh's changes in the sirius-web
checkout by default (requires SIRIUS_WEB_ROOT env var, generated/.generation-info, or prompt).

  PROJECT_NAME    One or more project names under generated/ to remove.
  --all           Remove every project under generated/.
  --no-uninstall  Only remove generated/<name>, leave the sirius-web checkout untouched.
  --yes           Do not ask for confirmation.

Examples:
  $0 --all
  $0 myExtension anotherExtension
  $0 --all --no-uninstall
EOF
}

ALL=false
UNINSTALL=true
ASSUME_YES=false
TARGETS=()

for arg in "$@"; do
  case "$arg" in
    --all) ALL=true ;;
    --uninstall) UNINSTALL=true ;; # kept for backwards compatibility, it's the default now
    --no-uninstall) UNINSTALL=false ;;
    --yes|-y) ASSUME_YES=true ;;
    -h|--help) usage; exit 0 ;;
    *) TARGETS+=("$arg") ;;
  esac
done

if [ ! -d "$GENERATED_DIR" ]; then
  echo "Nothing to clean: $GENERATED_DIR does not exist."
  exit 0
fi

if [ "$ALL" = true ]; then
  mapfile -t TARGETS < <(find "$GENERATED_DIR" -maxdepth 1 -mindepth 1 -type d ! -name ".*" -printf '%f\n' | sort)
fi

if [ "${#TARGETS[@]}" -eq 0 ]; then
  echo "No project names given. Use --all to remove every generated project, or pass names explicitly."
  usage
  exit 1
fi

uninstall_from_sirius_web() {
  local project_name="$1" group_id="$2"
  local sirius_web_root="${SIRIUS_WEB_ROOT:-}"
  if [ -z "$sirius_web_root" ]; then
    read -rp "Path to your sirius-web checkout (to uninstall ${project_name}): " sirius_web_root
  fi
  sirius_web_root="$(cd "$sirius_web_root" 2>/dev/null && pwd || true)"
  if [ -z "$sirius_web_root" ] || [ ! -f "$sirius_web_root/packages/pom.xml" ]; then
    echo "  ⚠ '$sirius_web_root' does not look like a sirius-web checkout, skipping uninstall for ${project_name}."
    return
  fi

  local packages_dir="$sirius_web_root/packages"
  local packages_pom="$packages_dir/pom.xml"
  local starters_pom="$packages_dir/starters/backend/pom.xml"
  local app_pom="$packages_dir/sirius-web/backend/sirius-web/pom.xml"

  echo "  • Removing ${packages_dir}/${project_name}"
  rm -rf "${packages_dir:?}/${project_name}"
  if [ -e "${packages_dir}/${project_name}" ]; then
    echo "  ⚠ ${packages_dir}/${project_name} could not be removed (check permissions / open file handles)."
  fi

  echo "  • Removing ${packages_dir}/starters/backend/${project_name}-starter"
  rm -rf "${packages_dir:?}/starters/backend/${project_name}-starter"
  if [ -e "${packages_dir}/starters/backend/${project_name}-starter" ]; then
    echo "  ⚠ ${packages_dir}/starters/backend/${project_name}-starter could not be removed (check permissions / open file handles)."
  fi

  if [ -f "$packages_pom" ]; then
    echo "  • Unregistering module from packages/pom.xml"
    sed -i "\|<module>${project_name}/backend</module>|d" "$packages_pom"
  fi

  if [ -f "$starters_pom" ]; then
    echo "  • Unregistering module from starters/backend/pom.xml"
    sed -i "\|<module>${project_name}-starter</module>|d" "$starters_pom"
  fi

  if [ -f "$app_pom" ]; then
    echo "  • Removing dependency from sirius-web app pom.xml"
    awk -v artifactId="${project_name}" '
      BEGIN { skip=0 }
      /<dependency>/ { block=$0; inblock=1; next }
      inblock && /<\/dependency>/ {
        block = block "\n" $0
        if (block ~ ("<artifactId>" artifactId "</artifactId>")) {
          inblock=0
          next
        }
        print block
        inblock=0
        next
      }
      inblock { block = block "\n" $0; next }
      { print }
    ' "$app_pom" > "$app_pom.tmp" && mv "$app_pom.tmp" "$app_pom"
  fi
}

REMOVED_COUNT=0

for name in "${TARGETS[@]}"; do
  TARGET_DIR="$GENERATED_DIR/$name"
  if [ ! -d "$TARGET_DIR" ]; then
    echo "Skipping '$name': not found under $GENERATED_DIR"
    continue
  fi

  if [ "$ASSUME_YES" != true ]; then
    read -rp "Remove generated/$name$( [ "$UNINSTALL" = true ] && echo ' and its sirius-web installation')? [y/N] " CONFIRM
    [[ "$CONFIRM" =~ ^[Yy]$ ]] || { echo "Skipped $name."; continue; }
  fi

  if [ "$UNINSTALL" = true ]; then
    GROUP_ID=""
    # shellcheck disable=SC1090
    [ -f "$TARGET_DIR/.project-info" ] && source "$TARGET_DIR/.project-info"
    # SIRIUS_WEB_ROOT is shared across all projects: env var wins, else generated/.generation-info.
    if [ -z "${SIRIUS_WEB_ROOT:-}" ] && [ -f "$GENERATION_INFO" ]; then
      SIRIUS_WEB_ROOT="$(grep '^SIRIUS_WEB_ROOT=' "$GENERATION_INFO" | cut -d= -f2-)"
    fi
    echo "Uninstalling $name from sirius-web..."
    uninstall_from_sirius_web "$name" "$GROUP_ID"
  fi

  echo "Removing generated/$name"
  rm -rf "$TARGET_DIR"
  REMOVED_COUNT=$((REMOVED_COUNT + 1))

  if [ -f "$GENERATION_INFO" ] && [ "$(grep '^PROJECT_NAME=' "$GENERATION_INFO" | cut -d= -f2-)" = "$name" ]; then
    rm -f "$GENERATION_INFO"
  fi
done

echo ""
if [ "$REMOVED_COUNT" -eq 0 ]; then
  echo "Nothing was removed."
  exit 1
fi
echo "✅ Clean complete ($REMOVED_COUNT removed)."
