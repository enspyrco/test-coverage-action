#!/bin/sh -l

# CWD = $GITHUB_WORKSPACE
chrlen=$INPUT_SERVICE-ACCOUNT-KEY
printf "package IS %s, key is %d char len.\n" $INPUT_PACKAGE-NAME $chrlen
flutter test --coverage
genhtml coverage/lcov.info -o coverage/$INPUT_PACKAGE-NAME
rm coverage/lcov.info
gzip -r coverage/$INPUT_PACKAGE-NAME
cd /app && dart pub get && dart run bin/deploy_coverage.dart