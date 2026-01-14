#!/bin/bash
# Resume or start a project session in Zellij
# Usage: resume-project.sh [project-path]

PROJECT_PATH="${1:-$(pwd)}"
PROJECT_NAME=$(basename "$PROJECT_PATH")

cd "$PROJECT_PATH" || exit 1

# Attach if exists, otherwise create with dev layout
zellij attach "$PROJECT_NAME" 2>/dev/null || zellij --layout dev --session "$PROJECT_NAME"
