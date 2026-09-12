#!/usr/bin/env bash
# Launch the OpenLane 2 RTL->GDSII flow for the current src/ (dockerized).
# Host has no yosys/openroad — the tools live in the OpenLane2 docker image.
# Usage: ./run_flow.sh [config.json]        (default: config.json)
set -euo pipefail
cd "$(dirname "$0")"
source "$HOME/ol2-env/bin/activate"
CONFIG="${1:-config.json}"
exec openlane --dockerized --flow Classic --design-dir "$(pwd)" "$CONFIG"