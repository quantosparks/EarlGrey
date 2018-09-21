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

#import "FTRBaseIntegrationTest.h"

@interface FTRWKWebViewTest : FTRBaseIntegrationTest
@end

@implementation FTRWKWebViewTest

- (void)setUp {
  [super setUp];
  [self openTestViewNamed:@"WKWebView"];
}

- (void)testNavigationToWKWebViewTestController {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TestWKWebView")]
      assertWithMatcher:grey_notNil()];
  [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"Local")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_kindOfClassName(@"WKScrollView")]
      assertWithMatcher:grey_notNil()];
}

- (void)testJavascriptEvaluationWithAReturnValue {
  EDORemoteVariable<NSString *> *javaScriptResult = [[EDORemoteVariable alloc] init];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TestWKWebView")]
      performAction:grey_javaScriptExecution(@"var foo = 1; foo + 1;", javaScriptResult)];
  XCTAssertEqualObjects(javaScriptResult.object, @"2");
}

- (void)testJavascriptEvaluationWithATimeoutAboveTheThreshold {
  NSError *error = nil;
  CFTimeInterval originalInteractionTimeout =
      GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);
  [[GREYConfiguration sharedConfiguration] setValue:@(1)
                                       forConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
  NSString *jsStringAboveTimeout =
      @"start = new Date().getTime(); while (new Date().getTime() < start + 3000);";
  // JS action timeout greater than the threshold.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TestWKWebView")]
      performAction:grey_javaScriptExecution(jsStringAboveTimeout, nil)
              error:&error];
  XCTAssertEqual(error.code, kGREYWKWebViewInteractionFailedErrorCode);
  NSString *timeoutErrorString = @"Interaction with WKWebView failed because of timeout";
  XCTAssertNotEqual([error.localizedDescription rangeOfString:timeoutErrorString].location,
                    NSNotFound);
  [[GREYConfiguration sharedConfiguration] setValue:@(originalInteractionTimeout)
                                       forConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
}

- (void)testJavascriptEvaluationWithATimeoutBelowTheThreshold {
  NSError *error = nil;
  CFTimeInterval originalInteractionTimeout =
      GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);
  [[GREYConfiguration sharedConfiguration] setValue:@(1)
                                       forConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
  EDORemoteVariable<NSString *> *javaScriptResult = [[EDORemoteVariable alloc] init];
  NSString *jsStringEqualTimeout =
      @"start = new Date().getTime(); while (new Date().getTime() < start + 200);"
      @"end = new Date().getTime(); end - start";
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TestWKWebView")]
      performAction:grey_javaScriptExecution(jsStringEqualTimeout, javaScriptResult)
              error:&error];
  XCTAssertNil(error, @"Error for a valid call is nil");
  XCTAssertGreaterThanOrEqual([javaScriptResult.object intValue], 200);
  [[GREYConfiguration sharedConfiguration] setValue:@(originalInteractionTimeout)
                                       forConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
}

- (void)testJavascriptExecutionError {
  EDORemoteVariable<NSString *> *javaScriptResult = [[EDORemoteVariable alloc] init];
  NSError *error;
  id<GREYAction> jsAction =
      grey_javaScriptExecution(@"document.body.getElementsByTagName(\"*\");", javaScriptResult);
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TestWKWebView")] performAction:jsAction
                                                                                      error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYWKWebViewInteractionFailedErrorCode);
}

@end
