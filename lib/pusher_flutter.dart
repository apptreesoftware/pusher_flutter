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


  /// Creates a [PusherFlutter] with the specified [apiKey] from pusher.
  ///
  /// The [apiKey] may not be null.
  PusherFlutter(this._apiKey) {
    _channel = new MethodChannel('plugins.apptreesoftware.com/pusher');
    _channel.invokeMethod('create', _apiKey);
    _connectivityEventChannel =
        new EventChannel('plugins.apptreesoftware.com/pusher_connection');
    _messageChannel =
        new EventChannel('plugins.apptreesoftware.com/pusher_message');
  }

  /// Connect to the pusher service.
  void connect() {
    _channel.invokeMethod('connect');
  }

  /// Disconnect from the pusher service
  void disconnect() {
    _channel.invokeMethod('disconnect');
  }

  /// Unsubscribe from a channel with the name [channelName]
  ///
  /// This will unsubscribe you from all events on that channel.
  void unsubscribe(String channelName) {
    _channel.invokeMethod('unsubscribe', channelName);
  }

  /// Subscribe to a channel with the name [channelName] for the event [event]
  ///
  /// Calling this method will cause any messages matching the [event] and [channelName]
  /// provided to be delivered to the [onMessage] method. After calling this you
  /// must listen to the [Stream] returned from [onMessage].
  void subscribe(String channelName, String event) {
    _channel.invokeMethod('subscribe', {"channel" : channelName, "event" : event});
  }

  /// Get the [Stream] of [PusherMessage] for the channels and events you've
  /// signed up for.
  ///
  Stream<PusherMessage> onMessage() {
    return _messageChannel
        .receiveBroadcastStream()
        .map(_toPusherMessage);
  }

  /// Get a [Stream] of [PusherConnectionState] events.
  /// Use this method to get notified about connection-related information.
  ///
  Stream<PusherConnectionState> get onConnectivityChanged =>
      _connectivityEventChannel
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

  PusherMessage _toPusherMessage(Map map) {
    return new PusherMessage(map['channel'], map['event'], map['body']);
  }
}

class PusherMessage {
  final String channelName;
  final String eventName;
  final Map body;

  PusherMessage(this.channelName, this.eventName, this.body);
}