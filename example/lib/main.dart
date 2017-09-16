import 'package:flutter/material.dart';
import 'package:pusher_flutter/pusher_flutter.dart';

void main() {
  runApp(new MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Map _latestMessage;
  PusherError _lastError;
  PusherConnectionState _connectionState;
  PusherFlutter pusher = new PusherFlutter("<your_key>");

  @override
  initState() {
    super.initState();
    pusher.onConnectivityChanged.listen((state) {
      setState(() {
        _connectionState = state;
        if (state == PusherConnectionState.connected) {
          _lastError = null;
        }
      });
    });
    pusher.onError.listen((err) => _lastError = err);
    _connectionState = PusherConnectionState.disconnected;
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
          appBar: new AppBar(
            title: new Text('Pusher example app.'),
          ),
          body: new Column(
            children: <Widget>[
              new Row(
                children: <Widget>[
                  new Text('Latest message ${_latestMessage.toString()}')
                ],
                mainAxisAlignment: MainAxisAlignment.center,
              ),
              buildConnectRow(context),
              buildErrorRow(context),
            ],
          )),
    );
  }

  Widget buildErrorRow(BuildContext context) {
    if (_lastError != null) {
      return new Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          new Text("Error: ${_lastError.message}")
        ],
      );
    } else {
      return new Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          new Text("No Errors")
        ],
      );
    }
  }

  Widget buildConnectRow(BuildContext context) {
    switch (_connectionState) {
      case PusherConnectionState.connected:
        return new Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new MaterialButton(
                onPressed: disconnect, child: new Text("Disconnect"))
          ],
        );
      case PusherConnectionState.disconnected:
        return new Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new MaterialButton(onPressed: connect, child: new Text("Connect"))
          ],
        );
      case PusherConnectionState.disconnecting:
        return new Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[new Text("Disconnecting...")],
        );
      case PusherConnectionState.connecting:
        return new Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[new Text("Connecting...")],
        );
      case PusherConnectionState.reconnectingWhenNetworkBecomesReachable:
        return new Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new Text("Will reconnect when network becomes available")
          ],
        );
      case PusherConnectionState.reconnecting:
        return new Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[new Text("Reconnecting...")],
        );
    }
    return new Text("Invalid state");
  }

  void connect() {
    pusher.connect();

    pusher.subscribe("test_channel", "test_event");
    pusher.subscribe("test_channel", "test_event2");

    pusher.subscribeAll("test_channel", ["test_event3", "test_event4"]);

    pusher.onMessage.listen((pusher) {
      setState(() => _latestMessage = pusher.body);
    });
  }

  void disconnect() {
    pusher.unsubscribe("test_channel");
    pusher.unsubscribe("test_channel2");
    pusher.disconnect();
  }
}
