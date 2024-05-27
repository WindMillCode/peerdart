Future<String> forceVP8(String sdpHere) async {
  //File f = File('lib/newTests/test.txt');
  List<String> value = sdpHere.split('\n');
  Map sdpDefinedCodecs = {};
  int videoLineIndex;
  bool h264first = false;
  bool vp8present = false;

  String newMediaDescription = '';
  RegExp findVideoLine = RegExp(r'm=video+');
  RegExp findCodec = RegExp(r'a=rtpmap:+');
  RegExp matchCodec = RegExp(r'(?<=a=rtpmap:)[0-9]+');
  RegExp extractCodecName = RegExp(r'(?<= )[A-Za-z0-9]+(?=/)');

  List<String> finalSDP = [];

  videoLineIndex = getVideoLineIndex(value);
  print('video line index $videoLineIndex');
  print(value[videoLineIndex]);
  List mediaDescription = value[videoLineIndex].split(' ');
  print(mediaDescription.skip(3).toList());
  List codecs = mediaDescription.skip(3).toList();

  for (int i = 0; i < value.length; i++) {
    if (findCodec.hasMatch(value[i])) {
      //print(value[i]);
      //print(matchCodec.stringMatch(value[i]));
      //print(extractCodecName.stringMatch(value[i]));
      sdpDefinedCodecs[matchCodec.stringMatch(value[i])] =
          extractCodecName.stringMatch(value[i]);
    }
  }
  print(sdpDefinedCodecs);

  int vp8Index = -1;
  if (sdpDefinedCodecs[codecs[0]] == 'H264') {
    h264first = true;
  }

  for (int idx = 0; idx < codecs.length; idx++) {
    if (sdpDefinedCodecs[codecs[idx]] == 'VP8') {
      vp8present = true;
      print('vp8 is present');
      vp8Index = idx;
    }
  }

  print(h264first);
  print(vp8present);
  if (h264first == true && vp8present == true) {
    print('flip flopping h264 and vp8');
    //list not changing value

    for (int x = 3; x < mediaDescription.length; x++) {
      print(sdpDefinedCodecs[mediaDescription[x]]);
      if (sdpDefinedCodecs[mediaDescription[x]] == 'VP8') {
        var tmp = mediaDescription[3];
        mediaDescription[3] = mediaDescription[x];
        mediaDescription[x] = tmp;
      }
    }

    print('new mediaScription');
    print(mediaDescription.join(' '));

    value[videoLineIndex] = mediaDescription.join(' ');
  }

  return value.join('\n');

  //return x.join('\n');
}


int getVideoLineIndex(List<String> sdp) {
  RegExp findVideoLine = RegExp(r'm=video+');
  for (var i = 0; i < sdp.length; i++) {
    RegExpMatch? match = findVideoLine.firstMatch(sdp[i]);
    if (match != null) {
      return i;
    }
  }
  return -1;
}
