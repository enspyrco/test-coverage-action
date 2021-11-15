# test-coverage-action

Generate &amp; deploy test coverage for Dart &amp; Flutter apps in a monorepo.

> [Project Notes](https://enspyrco.notion.site/test-coverage-action-467b548567774bee9e1f33bac59f9ca2)

Currently 
- Calculates coverage and generates a html summary
- Deploys the summary to Firebase Hosting.

Future Work
- Adds a comment to the PR with the coverage and whether it is a passing number.

## Setup

Setup guides can be found in the [User Docs](https://www.notion.so/enspyrco/User-Docs-08425ed98ebc423084e57fff4060376f).

## Usage

### Deploy coverage

Add a workflow (eg. `.github/workflows/main.yml`):

```yaml
name: Deploy coverage on each PR

on:
  pull_request:

jobs:
  build_and_preview:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: enspyrco/test-coverage-action@v0
        with:
          site_id: enspyrco
          service_account_key: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
          packages_path: packages/
          package_name: ${{ matrix.package_name }}
```

Note: FIREBASE_SERVICE_ACCOUNT may be named differently by the Firebase CLI. Use whatever the tool tells you to.

## Options

### `service_account_key` _{string}_ (required)

This is a service account JSON key. The easiest way to set it up is to run `firebase init hosting:github`. However, it can also be [created manually](./docs/service-account.md) then stored as an
[encrypted secret](https://help.github.com/en/actions/configuring-and-managing-workflows/creating-and-storing-encrypted-secrets).

### `site_id` _{string}_ (optional)

Identifies the firebase hosting site that will be used.  If you only have one site, the site id is the project id.
If there is a `.firebaserc` in the project directory, you can leave this option out and the project id will be used.

### `packages_path` _{string}_ (optional)

If the project is a multi-package (monorepo) project, provide the path to the packages.

### `package_name` _{string}_ (optional)

If the project is a multi-package (monorepo) project, provide the package name.
