//
// Copyright 2018 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "AppFramework/Event/GREYSyntheticEvents.h"

#import "AppFramework/Event/GREYTouchInjector.h"
#import "AppFramework/Synchronization/GREYDispatchQueueTracker.h"
#import "AppFramework/Synchronization/GREYUIThreadExecutor.h"
#import "CommonLib/Assertion/GREYAssertionDefines.h"
#import "CommonLib/Assertion/GREYFatalAsserts.h"
#import "CommonLib/Assertion/GREYThrowDefines.h"
#import "CommonLib/Error/GREYError.h"
#import "CommonLib/Error/GREYErrorConstants.h"
#import "CommonLib/Event/GREYTouchInfo.h"
#import "CommonLib/GREYAppleInternals.h"
#import "CommonLib/GREYConstants.h"
#import "CommonLib/GREYLogger.h"

#pragma mark - Implementation

/**
 *  Timeout for waiting for rotation to start and then again waiting for app to idle after it
 *  completes.
 */
static const CFTimeInterval kRotationTimeout = 10.0;

@implementation GREYSyntheticEvents {
  /**
   *  The touch injector that completes the touch sequence for an event.
   */
  GREYTouchInjector *_touchInjector;

  /**
   *  The last injected touch point.
   */
  NSValue *_lastInjectedTouchPoint;
}

+ (void)touchAlongPath:(NSArray *)touchPath
      relativeToWindow:(UIWindow *)window
           forDuration:(NSTimeInterval)duration {
  [self touchAlongMultiplePaths:@[ touchPath ] relativeToWindow:window forDuration:duration];
}

+ (void)touchAlongMultiplePaths:(NSArray *)touchPaths
               relativeToWindow:(UIWindow *)window
                    forDuration:(NSTimeInterval)duration {
  GREYThrowOnFailedCondition(touchPaths.count >= 1);
  GREYThrowOnFailedCondition(duration >= 0);

  NSUInteger firstTouchPathSize = [touchPaths[0] count];
  GREYSyntheticEvents *eventGenerator = [[GREYSyntheticEvents alloc] init];

  // Inject "begin" event for the first points of each path.
  [eventGenerator grey_beginTouchesAtPoints:[self grey_objectsAtIndex:0 ofArrays:touchPaths]
                           relativeToWindow:window
                          immediateDelivery:NO];

  // If the paths have a single point, then just inject an "end" event with the delay being the
  // provided duration. Otherwise, insert multiple "continue" events with delays being a fraction
  // of the duration, then inject an "end" event with no delay.
  if (firstTouchPathSize == 1) {
    [eventGenerator grey_endTouchesAtPoints:[self grey_objectsAtIndex:firstTouchPathSize - 1
                                                             ofArrays:touchPaths]
          timeElapsedSinceLastTouchDelivery:duration];
  } else {
    // Start injecting "continue touch" events, starting from the second position on the touch
    // path as it was already injected as a "begin touch" event.
    CFTimeInterval delayBetweenEachEvent = duration / (double)(firstTouchPathSize - 1);

    for (NSUInteger i = 1; i < firstTouchPathSize; i++) {
      [eventGenerator grey_continueTouchAtPoints:[self grey_objectsAtIndex:i ofArrays:touchPaths]
          afterTimeElapsedSinceLastTouchDelivery:delayBetweenEachEvent
                               immediateDelivery:NO];
    }

    [eventGenerator grey_endTouchesAtPoints:[self grey_objectsAtIndex:firstTouchPathSize - 1
                                                             ofArrays:touchPaths]
          timeElapsedSinceLastTouchDelivery:0];
  }
}

+ (BOOL)rotateDeviceToOrientation:(UIDeviceOrientation)deviceOrientation error:(NSError **)error {
  __block NSError *executionError;
  __block UIDeviceOrientation initialDeviceOrientation;
  BOOL success = [[GREYUIThreadExecutor sharedInstance]
      executeSyncWithTimeout:kRotationTimeout
                       block:^{
                         initialDeviceOrientation = [[UIDevice currentDevice] orientation];
                         GREYLogVerbose(
                             @"The current device's orientation is being rotated from %@ to: %@",
                             NSStringFromUIDeviceOrientation(initialDeviceOrientation),
                             NSStringFromUIDeviceOrientation(deviceOrientation));
                         [[UIDevice currentDevice] setOrientation:deviceOrientation animated:YES];
                       }
                       error:&executionError];

  if (!success) {
    *error = executionError;
    return NO;
  }

  // Verify that the device orientation actually changed to the requested orientation.
  __block UIDeviceOrientation currentOrientation = UIDeviceOrientationUnknown;
  success = [[GREYUIThreadExecutor sharedInstance]
      executeSyncWithTimeout:kRotationTimeout
                       block:^{
                         currentOrientation = [[UIDevice currentDevice] orientation];
                       }
                       error:&executionError];

  if (!success) {
    *error = executionError;
    return NO;
  } else if (currentOrientation != deviceOrientation) {
    NSString *errorDescription =
        [NSString stringWithFormat:
                      @"Device orientation mismatch. "
                      @"Before: %@. After Expected: %@. \nAfter Actual: %@.",
                      NSStringFromUIDeviceOrientation(initialDeviceOrientation),
                      NSStringFromUIDeviceOrientation(deviceOrientation),
                      NSStringFromUIDeviceOrientation(currentOrientation)];
    NSError *rotationError = GREYErrorMake(kGREYSyntheticEventInjectionErrorDomain,
                                           kGREYOrientationChangeFailedErrorCode, errorDescription);
    *error = rotationError;
    return NO;
  }
  return YES;
}

+ (BOOL)shakeDeviceWithError:(NSError **)errorOrNil {
  NSError *error;
  return [[GREYUIThreadExecutor sharedInstance]
      executeSyncWithTimeout:kRotationTimeout
                       block:^{
                         // Keep previous accelerometer events enabled value and force it to YES so
                         // that the shake motion is passed to the application.
                         UIApplication *application = [UIApplication sharedApplication];
                         BKSAccelerometer *accelerometer =
                             [[application _motionEvent] valueForKey:@"_motionAccelerometer"];
                         BOOL prevValue = accelerometer.accelerometerEventsEnabled;
                         accelerometer.accelerometerEventsEnabled = YES;

                         // This behaves exactly in the same manner that UIApplication handles the
                         // simulator "Shake Gesture" menu command.
                         [application _sendMotionBegan:UIEventSubtypeMotionShake];
                         [application _sendMotionEnded:UIEventSubtypeMotionShake];

                         accelerometer.accelerometerEventsEnabled = prevValue;
                       }
                       error:&error];
}

- (void)beginTouchAtPoint:(CGPoint)point
         relativeToWindow:(UIWindow *)window
        immediateDelivery:(BOOL)immediate {
  _lastInjectedTouchPoint = [NSValue valueWithCGPoint:point];
  [self grey_beginTouchesAtPoints:@[ _lastInjectedTouchPoint ]
                 relativeToWindow:window
                immediateDelivery:immediate];
}

- (void)continueTouchAtPoint:(CGPoint)point immediateDelivery:(BOOL)immediate {
  _lastInjectedTouchPoint = [NSValue valueWithCGPoint:point];
  [self grey_continueTouchAtPoints:@[ _lastInjectedTouchPoint ]
      afterTimeElapsedSinceLastTouchDelivery:0
                           immediateDelivery:immediate];
}

- (void)endTouch {
  [self grey_endTouchesAtPoints:@[ _lastInjectedTouchPoint ] timeElapsedSinceLastTouchDelivery:0];
}

#pragma mark - Private

// Given an array containing multiple arrays, returns an array with the index'th element of each
// array.
+ (NSArray *)grey_objectsAtIndex:(NSUInteger)index ofArrays:(NSArray *)arrayOfArrays {
  GREYFatalAssertWithMessage([arrayOfArrays count] > 0,
                             @"arrayOfArrays must contain at least one element.");
  NSUInteger firstArraySize = [arrayOfArrays[0] count];
  GREYFatalAssertWithMessage(index < firstArraySize,
                             @"index must be smaller than the size of the arrays.");

  NSMutableArray *output = [[NSMutableArray alloc] initWithCapacity:[arrayOfArrays count]];
  for (NSArray *array in arrayOfArrays) {
    GREYFatalAssertWithMessage([array count] == firstArraySize,
                               @"All arrays must be of the same size.");
    [output addObject:array[index]];
  }

  return output;
}

/**
 *  Begins interaction with new touches starting at multiple @c points. Touch will be delivered to
 *  the hit test view in @c window under point and will not end until @c endTouch is called.
 *
 *  @param points    Multiple points where touches should start.
 *  @param window    The window that contains the coordinates of the touch points.
 *  @param immediate If @c YES, this method blocks until touch is delivered, otherwise the touch is
 *                   enqueued for delivery the next time runloop drains.
 */
- (void)grey_beginTouchesAtPoints:(NSArray *)points
                 relativeToWindow:(UIWindow *)window
                immediateDelivery:(BOOL)immediate {
  GREYFatalAssertWithMessage(!_touchInjector,
                             @"Cannot call this method more than once until endTouch is called.");

  _touchInjector = [[GREYTouchInjector alloc] initWithWindow:window];
  GREYTouchInfo *touchInfo = [[GREYTouchInfo alloc] initWithPoints:points
                                                             phase:UITouchPhaseBegan
                                   deliveryTimeDeltaSinceLastTouch:0];
  [_touchInjector enqueueTouchInfoForDelivery:touchInfo];

  if (immediate) {
    [_touchInjector waitUntilAllTouchesAreDelivered];
  }
}

/**
 *  Enqueues the next touch to be delivered.
 *
 *  @param points     Multiple points at which the touches are to be made.
 *  @param seconds    An interval to wait after the every last touch event.
 *  @param immediate  if @c YES, this method blocks until touches are delivered, otherwise it is
 *                    enqueued for delivery the next time runloop drains.
 */
- (void)grey_continueTouchAtPoints:(NSArray *)points
    afterTimeElapsedSinceLastTouchDelivery:(NSTimeInterval)seconds
                         immediateDelivery:(BOOL)immediate {
  GREYTouchInfo *touchInfo = [[GREYTouchInfo alloc] initWithPoints:points
                                                             phase:UITouchPhaseMoved
                                   deliveryTimeDeltaSinceLastTouch:seconds];
  [_touchInjector enqueueTouchInfoForDelivery:touchInfo];
  if (immediate) {
    [_touchInjector waitUntilAllTouchesAreDelivered];
  }
}

/**
 *  Enqueues the final touch in a touch sequence to be delivered.
 *
 *  @param points  Multiple points at which the touches are to be made.
 *  @param seconds An interval to wait after the every last touch event.
 */
- (void)grey_endTouchesAtPoints:(NSArray *)points
    timeElapsedSinceLastTouchDelivery:(NSTimeInterval)seconds {
  GREYTouchInfo *touchInfo = [[GREYTouchInfo alloc] initWithPoints:points
                                                             phase:UITouchPhaseEnded
                                   deliveryTimeDeltaSinceLastTouch:seconds];
  [_touchInjector enqueueTouchInfoForDelivery:touchInfo];
  [_touchInjector waitUntilAllTouchesAreDelivered];

  _touchInjector = nil;
}

@end
