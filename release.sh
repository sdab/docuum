#!/usr/bin/env bash
set -euo pipefail

# This script generates release artifacts in a directory called `release`. It should be run from a
# macOS machine with an x86-64 processor. Usage:
#   ./release.sh

# The release process involves three pull requests:
# 1. Bump the version in `Cargo.toml`, run `cargo build` to update `Cargo.lock`, and update
#    `CHANGELOG.md` with information about the new version. Ship those changes as a pull request.
# 2. Run `cargo publish`.
# 3. Run this script and upload the files in the `release` directory to GitHub as release artifacts.
# 4. Build and upload the Docker image:
#      cd release
#      docker build --tag stephanmisc/docuum:0.8.0 .
#      docker push stephanmisc/docuum:0.8.0
# 5. Update the version in `install.sh` to point to the new release. Ship that change as another
#    pull request.

# We wrap everything in parentheses to ensure that any working directory changes with `cd` are local
# to this script and don't affect the calling user's shell.
(
  # x86-64 macOS build
  rm -rf target/release
  cargo build --release

  # x86-64 GNU/Linux build
  rm -rf artifacts
  toast release

  # Prepare the `release` directory.
  rm -rf release
  mkdir release

  # Copy the artifacts into the `release` directory.
  cp artifacts/docuum-x86_64-unknown-linux-gnu release/docuum-x86_64-unknown-linux-gnu
  cp target/release/docuum release/docuum-x86_64-apple-darwin

  # Compute checksums of the artifacts.
  cd release
  shasum --algorithm 256 --binary docuum-x86_64-apple-darwin > docuum-x86_64-apple-darwin.sha256
  shasum --algorithm 256 --binary docuum-x86_64-unknown-linux-gnu > docuum-x86_64-unknown-linux-gnu.sha256

  # Verify the checksums.
  shasum --algorithm 256 --check --status docuum-x86_64-apple-darwin.sha256
  shasum --algorithm 256 --check --status docuum-x86_64-unknown-linux-gnu.sha256
)
