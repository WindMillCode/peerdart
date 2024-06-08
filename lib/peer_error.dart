import 'package:events_emitter/events_emitter.dart';
import 'package:windmillcode_peerdart/enums.dart';

class PeerError<T> implements Exception {
  final T type;
  final String message;

  PeerError(this.type, this.message);

  @override
  String toString() => 'PeerError(type: $type, message: $message)';
}

class EventsWithError<ErrorType> {
  final void Function(PeerError<ErrorType>)? error;

  EventsWithError({required this.error});
}

class EventEmitterWithError<ErrorType extends String, Events extends EventsWithError<ErrorType>> extends EventEmitter {
  void emitError(ErrorType /*ErrorType */ type, dynamic error) {
    print('Error: $error'); // Replace with logger.error in your actual code
    try {
      String errorString = "";
      if (error is PeerErrorType) {
        errorString = error.value;
      } else if (error is String) {
        errorString = error;
      } else {
        errorString = error.toString();
      }
      emit('error', PeerError<ErrorType>(type, errorString).toString());
    } catch (err, stack) {
      print(err);
    }
  }
}
