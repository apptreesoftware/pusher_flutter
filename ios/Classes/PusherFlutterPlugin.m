#import "PusherFlutterPlugin.h"

@implementation PusherFlutterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"plugins.apptreesoftware.com/pusher"
            binaryMessenger:[registrar messenger]];
  PusherFlutterPlugin* instance = [[PusherFlutterPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];

  FlutterEventChannel *connectionEventChannel = [FlutterEventChannel eventChannelWithName:@"plugins.apptreesoftware.com/pusher_connection" binaryMessenger:[registrar messenger]];
  instance.connectivityStreamHandler = [[PusherConnectionStateStream alloc] init];
  [connectionEventChannel setStreamHandler:instance.connectivityStreamHandler];

  FlutterEventChannel *messageEventChannel = [FlutterEventChannel eventChannelWithName:@"plugins.apptreesoftware.com/pusher_message" binaryMessenger:[registrar messenger]];
  instance.messageStreamHandler = [[MessageStreamHandler alloc] init];
  [messageEventChannel setStreamHandler:instance.messageStreamHandler];
}

- (BOOL)pusher:(PTPusher *)pusher connectionWillConnect:(PTPusherConnection *)connection {
    [self.connectivityStreamHandler sendState:@"connecting"];
    return YES;
}

- (void)pusher:(PTPusher *)pusher connectionDidConnect:(PTPusherConnection *)connection {
    [self.connectivityStreamHandler sendState:@"connected"];

}

- (void)pusher:(PTPusher *)pusher connection:(PTPusherConnection *)connection didDisconnectWithError:(NSError *)error willAttemptReconnect:(BOOL)willAttemptReconnect {
    [self.connectivityStreamHandler sendState:@"disconnected"];
}

- (void)pusher:(PTPusher *)pusher connection:(PTPusherConnection *)connection failedWithError:(NSError *)error {
    [self.connectivityStreamHandler sendState:@"disconnected"];
}

- (BOOL)pusher:(PTPusher *)pusher connectionWillAutomaticallyReconnect:(PTPusherConnection *)connection afterDelay:(NSTimeInterval)delay {
    [self.connectivityStreamHandler sendState:@"reconnecting"];
    return YES;
}

- (void)pusher:(PTPusher *)pusher willAuthorizeChannel:(PTPusherChannel *)channel withAuthOperation:(PTPusherChannelAuthorizationOperation *)operation {

}

- (void)pusher:(PTPusher *)pusher didSubscribeToChannel:(PTPusherChannel *)channel {

}

- (void)pusher:(PTPusher *)pusher didUnsubscribeFromChannel:(PTPusherChannel *)channel {

}

- (void)pusher:(PTPusher *)pusher didFailToSubscribeToChannel:(PTPusherChannel *)channel withError:(NSError *)error {

}

- (void)pusher:(PTPusher *)pusher didReceiveErrorEvent:(PTPusherErrorEvent *)errorEvent {

}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if( [call.method isEqualToString:@"create"] ) {
    self.pusher = [PTPusher pusherWithKey:call.arguments delegate:self encrypted:YES];
      result(@(YES));
  } else if ([call.method isEqualToString:@"connect"]) {
    [self.pusher connect];
      result(@(YES));
  } else if ([call.method isEqualToString:@"disconnect"]) {
    [self.pusher disconnect];
      result(@(YES));
  } else if ([call.method isEqualToString:@"subscribe"]) {
    NSString *channelName= call.arguments[@"channel"];
    NSString *event = call.arguments[@"event"];
    PTPusherChannel *channel = [self.pusher channelNamed:channelName];
    if (!channel) {
      channel = [self.pusher subscribeToChannelNamed:channelName];
    }
    [self listenToChannel:channel forEvent:event];
      result(@(YES));
  } else if ([call.method isEqualToString:@"unsubscribe"]) {
    PTPusherChannel *channel = [self.pusher channelNamed:call.arguments];
    [channel removeAllBindings];
    if (channel) {
      [channel unsubscribe];
    }
    result(@(YES));
  }
  result(FlutterMethodNotImplemented);
}

- (void)listenToChannel:(PTPusherChannel * )channel forEvent:(NSString *)event {
  [channel bindToEventNamed:event handleWithBlock:^(PTPusherEvent *e) {
      [_messageStreamHandler send:channel.name event:event body:e.data];
  }];
}

@end

@implementation MessageStreamHandler {
 FlutterEventSink _eventSink;
}

- (FlutterError *_Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(FlutterEventSink)events {
    _eventSink = events;
    return nil;
}

- (void)send:(NSString *)channel event:(NSString *)event body:(id)body {
  if (_eventSink) {
    NSDictionary *dictionary = @{@"channel" : channel, @"event" : event, @"body" : body};
    _eventSink(dictionary);
  }
}

- (FlutterError *_Nullable)onCancelWithArguments:(id _Nullable)arguments {
    _eventSink = nil;
  return nil;
}

@end


@implementation PusherConnectionStateStream {
    FlutterEventSink _eventSink;
}

- (FlutterError *_Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(FlutterEventSink)events {
    _eventSink = events;
    return nil;
}

- (void)sendState:(NSString*)state {
    if (_eventSink) {
     _eventSink(state);
    }
}

- (FlutterError *_Nullable)onCancelWithArguments:(id _Nullable)arguments {
    _eventSink = nil;
    return nil;
}

@end
