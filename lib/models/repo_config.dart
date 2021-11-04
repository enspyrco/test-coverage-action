import 'dart:io';

class RepoConfig {
  // ignore: unused_element
  RepoConfig._();

  RepoConfig.detect() {
    var packagesPath = Platform.environment['INPUT_PACKAGES_PATH'] ?? '';
    var packageName = Platform.environment['INPUT_PACKAGE_NAME'] ?? '';

    print('packages path: $packageName, package name: $packageName');

    // add a trailing backslash to packagesPath if needed
    if (packagesPath.isNotEmpty && packageName.isNotEmpty) {
      isMultiPackage = true;
      dirPath =
          (packagesPath.startsWith('/') ? packagesPath : '/$packagesPath') +
              packageName;
    } else {
      isMultiPackage = false;
      dirPath = '';

      // throw to give helpful error message
      if ((packagesPath.isNotEmpty) ^ (packageName.isNotEmpty)) {
        throw 'packageName and packagesPath must both be provided or neither.';
      }
    }
  }

  late final bool isMultiPackage;
  late final String dirPath;
}
