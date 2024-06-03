// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'option_interfaces.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PeerConnectOption _$PeerConnectOptionFromJson(Map<String, dynamic> json) =>
    PeerConnectOption(
      label: json['label'] as String?,
      metadata: json['metadata'],
      serialization: json['serialization'] as String?,
      reliable: json['reliable'] as bool?,
      connectionId: json['connectionId'] as String?,
      payload: json['payload'],
      sdp: (json['sdp'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      constraints: json['constraints'] as Map<String, dynamic>?,
      type: json['type'] as String?,
      msg: json['msg'],
      candidate: json['candidate'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$PeerConnectOptionToJson(PeerConnectOption instance) =>
    <String, dynamic>{
      'label': instance.label,
      'metadata': instance.metadata,
      'serialization': instance.serialization,
      'reliable': instance.reliable,
      'connectionId': instance.connectionId,
      'payload': instance.payload,
      'constraints': instance.constraints,
      'sdp': instance.sdp,
      'type': instance.type,
      'msg': instance.msg,
      'candidate': instance.candidate,
    };
