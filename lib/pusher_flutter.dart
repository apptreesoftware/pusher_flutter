import 'dart:async';

import 'package:flutter/services.dart';

enum PusherConnectionState {
  connecting,
  connected,
  disconnecting,
  disconnected,
  reconnecting,
  reconnectingWhenNetworkBecomesReachable
}

class PusherFlutter {
  final String _apiKey;
  MethodChannel _channel;
  EventChannel _connectivityEventChannel;
  EventChannel _messageChannel;

  PusherFlutter(this._apiKey) {
    _channel = new MethodChannel('plugins.apptreesoftware.com/pusher');
    _channel.invokeMethod('create', _apiKey);
    _connectivityEventChannel =
        new EventChannel('plugins.apptreesoftware.com/pusher_connection');
    _messageChannel =
        new EventChannel('plugins.apptreesoftware.com/pusher_message');
  }

  void connect() {
    _channel.invokeMethod('connect');
  }

  void disconnect() {
    _channel.invokeMethod('disconnect');
  }

  void subscribe(String channelName, String eventName) {
    _channel.invokeMethod(
        'subscribe', {"channel": channelName, "event": eventName});
  }

  void unsubscribe(String channelName) {
    _channel.invokeMethod('unsubscribe', channelName);
  }

  Stream<Map> onMessage(String channelName, String eventName) => _messageChannel
      .receiveBroadcastStream()
      .where((info) =>
          info['channel'] == channelName && info['event'] == eventName)
      .map((info) => info['body']);

  Stream<PusherConnectionState> get onConnectivityChanged => _connectivityEventChannel
      .receiveBroadcastStream()
      .map(_connectivityStringToState);

  PusherConnectionState _connectivityStringToState(String string) {
    switch (string) {
      case 'connecting':
        return PusherConnectionState.connecting;
      case 'connected':
        return PusherConnectionState.connected;
      case 'disconnected':
        return PusherConnectionState.disconnected;
      case 'disconnecting':
        return PusherConnectionState.disconnecting;
      case 'reconnecting':
        return PusherConnectionState.reconnecting;
      case 'reconnectingWhenNetworkBecomesReachable':
        return PusherConnectionState.reconnectingWhenNetworkBecomesReachable;
    }
    return PusherConnectionState.disconnected;
  }
}
