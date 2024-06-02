import 'dart:async';
import 'dart:typed_data';
import 'package:events_emitter/events_emitter.dart';
import 'logger.dart';

class EncodingQueue extends EventEmitter {
  List<Uint8List> _queue = [];
  bool _processing = false;

  List<Uint8List> get queue => _queue;
  int get size => _queue.length;
  bool get processing => _processing;

  void enque(Uint8List data) {
    _queue.add(data);

    if (_processing) return;

    _doNextTask();
  }

  void destroy() {
    _queue.clear();
  }

  void _doNextTask() {
    if (_queue.isEmpty || _processing) return;

    _processing = true;
    Uint8List data = _queue.removeAt(0);
    _processData(data);
  }

  void _processData(Uint8List data) async {
    try {
      // Simulate async processing of data
      await Future.delayed(Duration(milliseconds: 100));
      _processing = false;
      emit('done', data);
      _doNextTask();
    } catch (e) {
      logger.error('EncodingQueue error: $e');
      _processing = false;
      destroy();
      emit('error', e);
    }
  }
}
