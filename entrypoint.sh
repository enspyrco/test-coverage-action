#!/bin/sh -l

cd $GITHUB_WORKSPACE
flutter test --coverage
genhtml coverage/lcov.info -o html
