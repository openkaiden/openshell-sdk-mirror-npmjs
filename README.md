# openshell-sdk-mirror-npmjs

Mirrors [`@nvidia/openshell-sdk`](https://github.com/NVIDIA/OpenShell/pkgs/npm/openshell-sdk) from GitHub Packages to npmjs.org as [`@openkaiden/opnshll-sdk`](https://www.npmjs.com/package/@openkaiden/opnshll-sdk).

## How it works

A nightly GitHub Actions workflow (`sync.yaml`):

1. Fetches the latest version of `@nvidia/openshell-sdk` from `npm.pkg.github.com`
2. Checks whether that version already exists on npmjs.org as `@openkaiden/opnshll-sdk`
3. If not, downloads the tarball, rewrites `package.json` (name, scope, publishConfig), and publishes to npmjs with OIDC provenance

The workflow can also be triggered manually via `workflow_dispatch` with an optional version input.

## Manual usage

The scripts can be run outside of GitHub Actions to publish a specific version:

```bash
export GITHUB_TOKEN="<token-with-read:packages-scope>"
./scripts/publish-version.sh 0.0.116
```

This will download, repackage, and publish `@openkaiden/opnshll-sdk@0.0.116` to npmjs.org. You must be logged in to npm (`npm login`) beforehand.

To sync the latest version automatically:

```bash
./scripts/publish-version.sh
```

### Individual scripts

| Script | Purpose |
|---|---|
| `scripts/fetch-latest-version.sh` | Print the latest version from GitHub Packages |
| `scripts/check-published.sh <version>` | Exit 0 if the version exists on npmjs, 1 if not |
| `scripts/repackage.sh <version>` | Download, rewrite, and repack the tarball |
| `scripts/publish-version.sh [version]` | Full sync orchestrator |

## First-time setup

OIDC trusted publishing requires the package to already exist on npmjs.org:

1. Run `npm login` locally
2. Publish the initial version: `./scripts/publish-version.sh <version>`
3. On npmjs.org, go to the package settings and configure **Trusted Publishing**, linking it to this repository (`openkaiden/openshell-sdk-mirror-npmjs`) and the `sync.yaml` workflow

After this, the nightly workflow handles everything automatically with no npm token needed.

## Development

### Prerequisites

- [ShellCheck](https://www.shellcheck.net/) for linting
- [bats-core](https://github.com/bats-core/bats-core) for testing
- `jq` for JSON manipulation

On macOS:

```bash
brew install shellcheck bats-core jq
```

### Running tests

```bash
# Install test libraries (one-time)
./test/setup-libs.sh

# Lint
shellcheck scripts/*.sh

# Test
bats test/
```

### PR checks

Pull requests automatically run ShellCheck and bats tests on both Ubuntu and macOS via the `pr-check.yaml` workflow.

## License

[Apache License 2.0](LICENSE)
