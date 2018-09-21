//
// Copyright 2017 Google Inc.
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

#import "CommonLib/Provider/GREYProvider.h"

/**
 *  A provider for UIApplication windows. By default, all application windows are returned unless
 *  this provider is initialized with custom windows.
 */
@interface GREYUIWindowProvider : NSObject <GREYProvider>

/**
 *  Class method to get a provider with the specified @c windows.
 *
 *  @param windows An array of UIApplication windows to populate the provider.
 *
 *  @return A GREYUIWindowProvider instance populated with the UIApplication windows in @c windows.
 */
+ (instancetype)providerWithWindows:(NSArray *)windows;

/**
 *  Class method to get a provider with all the windows currently registed with the app.
 *
 *  @param includeStatusBar Should the status bar be included in the list of windows.
 *
 *  @return A GREYUIWindowProvider instance populated by all windows currently
 *          registered with the app.
 */
+ (instancetype)providerWithAllWindowsWithStatusBar:(BOOL)includeStatusBar;

/**
 *  @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 *  Designated Initializer.
 *
 *  @param windows          UIApplication windows to populate the provider with. If @c windows is
 *                          @c nil, it will initialize this provider with all windows currently
 *                          registered with the app. Use initWithAllWindowsWithStatusBar
 *                          constructor instead to make your intention explicit.
 *  @param includeStatusBar Should the status bar be included in the list of windows.
 *
 *  @return A GREYUIWindowProvider instance, populated with the specified windows.
 */
- (instancetype)initWithWindows:(NSArray *)windows
                  withStatusBar:(BOOL)includeStatusBar NS_DESIGNATED_INITIALIZER;

/**
 *  Initializes this provider with all application windows.
 *
 *  @param includeStatusBar Should the status bar be included in the list of windows.
 *
 *  @return A GREYUIWindowProvider instance populated by all windows currently
 *          registered with the app.
 */
- (instancetype)initWithAllWindowsWithStatusBar:(BOOL)includeStatusBar;

/**
 *  Returns all application windows ordered by window-level from back to front.
 *
 *  @param includeStatusBar Include the status bar in the window hierarchy.
 *
 *  @return A set of all application windows ordered by window-level from back to front.
 */
+ (NSArray *)allWindowsWithStatusBar:(BOOL)includeStatusBar;

#pragma mark - GREYProvider

/**
 *
 *  @return An enumerator for @c windows populating the window provider.
 */
- (NSEnumerator *)dataEnumerator;

@end
