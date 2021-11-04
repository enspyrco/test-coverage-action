import 'dart:io';

void printIfDebugging(Object object) {
  if (Platform.environment['DEBUGGING'] == 'true') {
    print(object);
  }
}
