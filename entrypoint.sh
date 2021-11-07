#!/bin/sh -l

# CWD = $GITHUB_WORKSPACE
export PACKAGE_PATH=${INPUT_PACKAGES_PATH}${INPUT_PACKAGE_NAME:+/$INPUT_PACKAGE_NAME}
echo "bash: CWD = $PWD, GITHUB_WORKSPACE = $GITHUB_WORKSPACE, PACKAGE_PATH = $PACKAGE_PATH"
echo "Contents of CWD:"
echo $(ls)
export PACKAGE_PATH=${PACKAGE_PATH:-.} # if single package repo set package path to .
echo ${PACKAGE_PATH-.}
cd ${PACKAGE_PATH-.} && dart pub get && flutter pub run build_runner build ; flutter test --coverage && genhtml coverage/lcov.info -o coverage
echo "Downloading deps for the Action's Dart app."
cd /app && dart pub get
echo "Running the Action's Dart app."
cd $GITHUB_WORKSPACE && dart run /app/bin/deploy_coverage.dart
