#import <Flutter/Flutter.h>
#import <Pusher/Pusher.h>

@class MessageStreamHandler;
@class PusherConnectionStateStream;

@interface PusherFlutterPlugin : NSObject<FlutterPlugin, PTPusherDelegate>
    @property PTPusher *pusher;
    @property MessageStreamHandler *messageStreamHandler;
    @property PusherConnectionStateStream *connectivityStreamHandler;
@end

@interface MessageStreamHandler : NSObject<FlutterStreamHandler>
- (void)send:(NSString *)channel event:(NSString *)event body:(NSDictionary *)body;
@end

@interface PusherConnectionStateStream : NSObject <FlutterStreamHandler>
- (void)sendState:(NSString*)state;
@end
