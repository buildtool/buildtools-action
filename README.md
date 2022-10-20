<p align="center">
  <h3 align="center">Setup Buildtool Action</h3>
  <p align="center"><a href="https://github.com/features/actions">GitHub Action</a> for <a href="https://buildtools.io/">Buildtool</a></p>
  <p align="center">
    <a href="https://github.com/buildtool/setup-buildtools-action/releases/latest"><img alt="GitHub release" src="https://img.shields.io/github/release/buildtool/buildtools-action.svg?logo=github"></a>
    <a href="https://github.com/marketplace/actions/setup-buildtools"><img alt="GitHub marketplace" src="https://img.shields.io/badge/marketplace-buildtools--action-blue?logo=github"></a>
  </p>
</p>

---

# setup-buildtools-action

This action downloads and installs [buildtools](https://buildtools.io/) and adds it to `$PATH`
At the moment it only supports Linux runners.

## Usage

Below is a simple snippet to use this action.

```yaml
name: example


on:
  push:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v1
      - uses: buildtool/setup-buildtools-action@v1
      - run: build```
```

To specify a specific version of build-tools:

```yaml

name: example with version

on:
  push:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v1
      - uses: buildtool/setup-buildtools-action@v1
        with:
          buildtools-version: 0.22.3
      - run: build
```

| Name                 | Type    | Description                                 |
|----------------------|---------|---------------------------------------------|
| `buildtools-version` | String  | Buildtool version, defaults to `latest`     |
| `debug-log  `        | String  | Enable verbose logging, defaults to `false` |

## License

MIT. See `LICENSE` for more details.

