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

#import "AppFramework/Matcher/GREYAllOf.h"

#import "CommonLib/Assertion/GREYThrowDefines.h"
#import "CommonLib/Matcher/GREYDescription.h"
#import "CommonLib/Matcher/GREYStringDescription.h"

@implementation GREYAllOf {
  NSArray<id<GREYMatcher>> *_matchers;
}

- (instancetype)initWithMatchers:(NSArray<id<GREYMatcher>> *)matchers {
  GREYThrowOnFailedCondition(matchers.count > 0);

  self = [super init];
  if (self) {
    NSUInteger numOfMatchers = matchers.count;
    NSMutableArray *matchersCopy = [[NSMutableArray alloc] initWithCapacity:numOfMatchers];
    // Explicitly copy over the elements because the array can be a remote object.
    for (NSUInteger i = 0; i < numOfMatchers; ++i) {
      [matchersCopy addObject:[matchers objectAtIndex:i]];
    }
    _matchers = [NSArray arrayWithArray:matchersCopy];
  }
  return self;
}

#pragma mark - GREYMatcher

- (BOOL)matches:(id)item {
  return [self matches:item describingMismatchTo:[[GREYStringDescription alloc] init]];
}

- (BOOL)matches:(id)item describingMismatchTo:(id<GREYDescription>)mismatchDescription {
  for (id<GREYMatcher> matcher in _matchers) {
    if (![matcher matches:item describingMismatchTo:mismatchDescription]) {
      return NO;
    }
  }
  return YES;
}

- (void)describeTo:(id<GREYDescription>)description {
  [description appendText:@"("];
  for (NSUInteger i = 0; i < _matchers.count - 1; i++) {
    [[description appendDescriptionOf:_matchers[i]] appendText:@" && "];
  }
  [description appendDescriptionOf:_matchers[_matchers.count - 1]];
  [description appendText:@")"];
}

@end
