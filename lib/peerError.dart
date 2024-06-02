import 'package:events_emitter/events_emitter.dart';

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

class EventEmitterWithError<
    ErrorType extends String,
    Events extends EventsWithError<ErrorType>
  > extends EventEmitter {
  void emitError(dynamic /*ErrorType */ type, dynamic error) {
    print('Error: $error'); // Replace with logger.error in your actual code

    emit('error', PeerError<ErrorType>(type, error.toString()));
  }
}
