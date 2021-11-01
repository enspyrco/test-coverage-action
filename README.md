# test-coverage-action

Generate &amp; deploy test coverage for Dart &amp; Flutter apps in a monorepo.

> [Project Notes](https://enspyrco.notion.site/test-coverage-action-467b548567774bee9e1f33bac59f9ca2)

Currently 
- Calculates coverage and generates a html summary
- Deploys the summary to Firebase Hosting.

Future Work
- Adds a comment to the PR with the coverage and whether it is a passing number.

## Setup

Setup guides can be found in the [Projects Notes > Documentation](https://enspyrco.notion.site/Documentation-ca43453f811f456dae4d7dbcd04a41a6).

## Usage

### Deploy coverage

Add a workflow (`.github/workflows/main.yml`):

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
          repoToken: "${{ secrets.GITHUB_TOKEN }}"
          serviceAccountKey: "${{ secrets.FIREBASE_SERVICE_ACCOUNT_SECRET }}"
```

Note: FIREBASE_SERVICE_ACCOUNT_SECRET may be named differently by the Firebase CLI. Use whatever the tool tells you to.

## Options

### `serviceAccountKey` _{string}_ (required)

This is a service account JSON key. The easiest way to set it up is to run `firebase init hosting:github`. However, it can also be [created manually](./docs/service-account.md) then stored as an
[encrypted secret](https://help.github.com/en/actions/configuring-and-managing-workflows/creating-and-storing-encrypted-secrets).

### `repoToken` _{string}_

Adding `repoToken: "${{secrets.GITHUB_TOKEN}}"` lets the action comment on PRs
with the coverage info. You don't need to set
this secret yourself - GitHub sets it automatically.
