import 'dart:io';

class RepoConfig {
  // ignore: unused_element
  RepoConfig._();

  RepoConfig.detect() {
    var packagesPath = Platform.environment['INPUT_PACKAGES_PATH'];
    var packageName = Platform.environment['INPUT_PACKAGE_NAME'];

    print('packages path: $packageName, package name: $packageName');

    // add a trailing backslash to packagesPath if needed
    if (packagesPath != null && packageName != null) {
      isMultiPackage = true;
      dirName =
          (packagesPath.startsWith('/') ? packagesPath : '/$packagesPath') +
              packageName;
    } else {
      isMultiPackage = false;
      if ((packagesPath == null) ^ (packageName == null)) {
        throw 'packageName and packagesPath must both be provided or neither.';
      }
    }
  }

  late final bool isMultiPackage;
  late final String dirName;
}
