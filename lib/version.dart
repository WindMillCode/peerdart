// import 'package:pubspec/pubspec.dart';

Future<String> getVersion() async {
  // final pubspec = await PubSpec.load(Directory.current);
  // final version = pubspec.version?.toString();
  // final versionParts = version!.split('.');

  // if (versionParts.length == 3) {
  //   final patch = versionParts[2];
  //   if (patch.length > 1 && patch[0] != '0') {
  //     versionParts[2] = patch.substring(0, 1);
  //   }
  // }

  // return versionParts.join('.');
  return '1.5.4';
}