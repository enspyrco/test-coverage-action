#!/bin/sh -l

# CWD = $GITHUB_WORKSPACE
flutter test --coverage
genhtml coverage/lcov.info -o coverage/$INPUT_PACKAGE_NAME
rm coverage/lcov.info
gzip -r coverage/$INPUT_PACKAGE_NAME
cd /app && dart pub get && dart run bin/deploy_coverage.dart