#!/usr/bin/env bash

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

force=false
repository="github.com/streamingfast/substreams-tron"

main() {
  pushd "$ROOT" &> /dev/null

  while getopts "hf" opt; do
    case $opt in
      h) usage && exit 0;;
      f) force=true;;
      \?) usage_error "Invalid option: -$OPTARG";;
    esac
  done
  shift $((OPTIND-1))

  version="$1"; shift
  if [[ $version == "" ]]; then
    usage_error "parameter <version> is required"
  fi

  version="${version#v}" # Remove leading 'v' if present

  check_sd
  check_git_clean

  sd 'version: v.*' "version: v${version}" substreams.yaml
  sd '## Unreleased' "## [${version}](https://${repository}/releases/tag/v${version})" CHANGELOG.md

  if [[ -n $(git status --porcelain) ]]; then
    git add -A .
    git commit -m "Preparing release of ${version}"
  fi
}

check_sd() {
  if ! command -v sd &> /dev/null; then
    echo "ERROR: 'sd' is required but was not found on your system."
    echo "Install it with:"
    echo "  brew install sd     # macOS (Homebrew)"
    echo "  cargo install sd    # Rust/cargo users"
    echo "  # Or see https://github.com/chmln/sd for more options."
    exit 1
  fi
}

check_git_clean() {
  if [[ "$force" == true ]]; then
    return
  fi

  if [[ -n $(git status --porcelain) ]]; then
    echo "ERROR: Your git working directory is not clean. Please commit or stash your changes before running this script."
    exit 1
  fi
}

usage_error() {
  message="$1"
  exit_code="$2"

  echo "ERROR: $message"
  echo ""
  usage
  exit ${exit_code:-1}
}

usage() {
  echo "usage: .sfreleaser.pre-release.sh <version>"
  echo ""
  echo "Run the necessary pre-release tasks for updating the version of"
  echo "the project in various files:"
  echo ""
  echo "This script will update the following files with the new version:"
  echo "  - substreams.yaml: Updates the 'version' field to v<version>"
  echo "  - CHANGELOG.md: Replaces '## Unreleased' with '## <version>'"
  echo ""
  echo "Options"
  echo "    -f          Force the script to run even if the git working directory is not clean"
  echo "    -h          Display help about this script"
}

main "$@"