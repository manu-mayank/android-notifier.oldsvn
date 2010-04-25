//
//  Notification.m
//  MacDroidNotifier
//
//  Created by Rodrigo Damazio on 25/12/09.
//

#import "Notification.h"


@implementation Notification

@synthesize deviceId;
@synthesize notificationId;
@synthesize type;
@synthesize contents;
@synthesize data;

- (id)initWithDeviceId:(NSString *)deviceIdParam
    withNotificationId:(NSString *)notificationIdParam
              withType:(NotificationType)typeParam
          withContents:(NSString *)contentsParam
              withData:(NSString *)dataParam {
  if (self = [super init]) {
    deviceId = [deviceIdParam copy];
    notificationId = [notificationIdParam copy];
    type = typeParam;
    contents = [contentsParam copy];
    data = [dataParam copy];
  }
  return self;
}

- (void)dealloc {
  [deviceId release];
  [notificationId release];
  [contents release];
  [data release];
  [super dealloc];
}

+ (NSString *)descriptionFromParts:(NSArray *)parts
                        startingAt:(NSUInteger)firstPart
                    withTotalParts:(NSUInteger)totalParts {
  NSUInteger numParts = [parts count];
  NSString *contents;
  if (numParts > totalParts) {
    // Oops, we broke down the description, put it back together
    NSRange contentRange = NSMakeRange(firstPart, numParts - totalParts + 1);
    NSArray *contentsParts = [parts subarrayWithRange:contentRange];
    contents = [contentsParts componentsJoinedByString:@"/"];
  } else {
    contents = [parts objectAtIndex:firstPart];
  }
  return contents;
}

+ (Notification *)notificationFromV2Parts:(NSArray *)parts {
  NSUInteger numParts = [parts count];
  if (numParts < 6) {
    return nil;
  }

  // Part 0 is "v2"
  NSString *deviceId = [parts objectAtIndex:1];
  NSString *notificationId = [parts objectAtIndex:2];
  NSString *typeStr = [parts objectAtIndex:3];
  NSString *data = [parts objectAtIndex:4];
  NSString *contents = [self descriptionFromParts:parts
                                       startingAt:5
                                   withTotalParts:6];

  NotificationType type;
  if (![self setNotificationType:&type fromString:typeStr]) {
    return nil;
  }

  return [[[Notification alloc] initWithDeviceId:deviceId
                              withNotificationId:notificationId
                                        withType:type
                                    withContents:contents
                                        withData:data] autorelease];
}

+ (Notification *)notificationFromV1Parts:(NSArray *)parts {
  NSUInteger numParts = [parts count];
  if (numParts < 4) {
    return nil;
  }

  NSString *deviceId = [parts objectAtIndex:0];
  NSString *notificationId = [parts objectAtIndex:1];
  NSString *typeStr = [parts objectAtIndex:2];
  NSString *contents = [self descriptionFromParts:parts
                                       startingAt:3
                                   withTotalParts:4];

  NotificationType type;
  if (![self setNotificationType:&type fromString:typeStr]) {
    return nil;
  }

  return [[[Notification alloc] initWithDeviceId:deviceId
                              withNotificationId:notificationId
                                        withType:type
                                    withContents:contents
                                        withData:@""] autorelease];
}

+ (Notification *)notificationFromString:(NSString *)serialized {
  NSArray *parts = [serialized componentsSeparatedByString:@"/"];

  Notification *result;
  if ([parts count] > 0 &&
      [[parts objectAtIndex:0] isEqualToString:@"v2"]) {
    result = [self notificationFromV2Parts:parts];
  } else {
    result = [self notificationFromV1Parts:parts];
  }

  if (!result) {
    NSLog(@"Malformed notification: '%@'", serialized);
  }

  return result;
}

- (BOOL)isEqualToNotification:(Notification *)notification {
  return [[notification deviceId] isEqualToString:[self deviceId]] &&
         [[notification notificationId] isEqualToString:[self notificationId]] &&
         ([notification type] == type) &&
         [[notification contents] isEqualToString:[self contents]] &&
         [[notification data] isEqualToString:[self data]];
}

- (NSString *)description {
  NSString *typeStr = [Notification stringFromNotificationType:type];
  if (!typeStr) typeStr = @"UNKNOWN";

  return [NSString stringWithFormat:@"Id=%@; DeviceId=%@; Type=%@; Data=%@; Contents=%@",
          notificationId, deviceId, typeStr, data, contents];
}

- (NSString *)rawNotificationString {
  NSString *typeStr = [Notification stringFromNotificationType:type];
  if (!typeStr) typeStr = @"UNKNOWN";
  
  return [NSString stringWithFormat:@"%@/%@/%@/%@",
          deviceId, notificationId, typeStr, contents];  
}

+ (BOOL)setNotificationType:(NotificationType *)type
                 fromString:(NSString *)typeStr {
  if ([typeStr isEqualToString:@"RING"]) {
    *type = RING;
  } else if ([typeStr isEqualToString:@"BATTERY"]) {
    *type = BATTERY;
  } else if ([typeStr isEqualToString:@"SMS"]) {
    *type = SMS;
  } else if ([typeStr isEqualToString:@"MMS"]) {
    *type = MMS;
  } else if ([typeStr isEqualToString:@"VOICEMAIL"]) {
    *type = VOICEMAIL;
  } else if ([typeStr isEqualToString:@"PING"]) {
    *type = PING;
  } else {
    return NO;
  }
  return YES;
}

+ (NSString *)stringFromNotificationType:(NotificationType)type {
  switch (type) {
    case RING:
      return @"RING";
    case BATTERY:
      return @"BATTERY";
    case SMS:
      return @"SMS";
    case MMS:
      return @"MMS";
    case VOICEMAIL:
      return @"VOICEMAIL";
    case PING:
      return @"PING";
    default:
      return nil;
  }
}

@end
