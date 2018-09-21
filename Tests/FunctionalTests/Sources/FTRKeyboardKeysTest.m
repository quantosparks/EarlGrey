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

// Note: GREYKeyboard should not be used in test cases of EarlGrey users. We are only using it here
// for test purpose.
#import "AppFramework/Keyboard/GREYKeyboard.h"
#import "GREYHostApplicationDistantObject+KeyboardKeysTest.h"
#import "FTRFailureHandler.h"
#import "Service/Sources/NSObject+EDOValueObject.h"

@interface FTRKeyboardKeysTest : FTRBaseIntegrationTest
@end

@interface GREYKeyboard (FTRExposedForTesting)
// expose shiftKeyLabels property for testing.
@property(class, readonly) NSArray *shiftKeyLabels;
@end

// TODO: 3 tests are not ported since GREYActionBlock is not supported by eDO // // NOLINT
// on test side. Will need to find workaround for it.
@implementation FTRKeyboardKeysTest

- (void)setUp {
  [super setUp];
  [self openTestViewNamed:@"Typing Views"];
}

- (void)testTypingAtBeginning {
  [[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:[GREYActions actionForTypeText:@"Foo"]]
      performAction:[GREYActions actionForTypeText:@"Bar" atPosition:0]]
      assertWithMatcher:grey_text(@"BarFoo")];
}

- (void)testTypingAtEnd {
  [[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:[GREYActions actionForTypeText:@"Foo"]]
      performAction:[GREYActions actionForTypeText:@"Bar" atPosition:-1]]
      assertWithMatcher:grey_text(@"FooBar")];
}

- (void)testTypingInMiddle {
  [[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:[GREYActions actionForTypeText:@"Foo"]]
      performAction:[GREYActions actionForTypeText:@"Bar" atPosition:2]]
      assertWithMatcher:grey_text(@"FoBaro")];
}

- (void)testTypingInMiddleOfBigString {
  id<GREYAction> typeLongTextAction =
      [GREYActions actionForTypeText:@"This string is a little too long for this text field!"];
  [[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:typeLongTextAction]
      performAction:[GREYActions actionForTypeText:@"Foo" atPosition:1]]
      assertWithMatcher:grey_text(@"TFoohis string is a little too long for this text field!")];
}

- (void)testTypingAfterTappingOnTextField {
  [[[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:[GREYActions actionForTap]]
      performAction:[GREYActions actionForTypeText:@"foo"]]
      performAction:[GREYActions actionForClearText]] assertWithMatcher:grey_text(@"")];
}

- (void)testClearAfterTyping {
  [[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:[GREYActions actionForTypeText:@"Foo"]]
      performAction:[GREYActions actionForClearText]] assertWithMatcher:grey_text(@"")];
}

- (void)testClearAfterClearing {
  [[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:[GREYActions actionForClearText]]
      performAction:[GREYActions actionForClearText]] assertWithMatcher:grey_text(@"")];
}

- (void)testClearAndType_TypeShort {
  [[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:[GREYActions actionForClearText]]
      performAction:[GREYActions actionForTypeText:@"Foo"]] assertWithMatcher:grey_text(@"Foo")];
}

- (void)testTypeAfterClearing_ClearThenType {
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:[GREYActions actionForTypeText:@"f"]] assertWithMatcher:grey_text(@"f")];

  [[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:[GREYActions actionForClearText]]
      performAction:[GREYActions actionForTypeText:@"g"]] assertWithMatcher:grey_text(@"g")];
}

- (void)testTypeAfterClearing_TypeLong {
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:[GREYActions actionForTypeText:@"This is a long string"]]
      assertWithMatcher:grey_text(@"This is a long string")];

  [[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:[GREYActions actionForClearText]]
      performAction:[GREYActions actionForTypeText:@"short string"]]
      assertWithMatcher:grey_text(@"short string")];
}

- (void)testNonTypistKeyboardInteraction {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:[GREYActions actionForTap]];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"a")]
      performAction:[GREYActions actionForTap]];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"b")]
      performAction:[GREYActions actionForTap]];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"c")]
      performAction:[GREYActions actionForTap]];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"return")]
      performAction:[GREYActions actionForTap]];
}

- (void)testNonTypingTextField {
  [EarlGrey setFailureHandler:[[FTRFailureHandler alloc] init]];

  @try {
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"NonTypingTextField")]
        performAction:[GREYActions actionForTypeText:@"Should Fail"]];
    GREYFail(@"Should throw an exception");
  } @catch (NSException *exception) {
    NSRange exceptionRange =
        [[exception reason] rangeOfString:@"Keyboard did not appear after tapping on element"];
    GREYAssertTrue(exceptionRange.length > 0,
                   @"Should throw exception indicating keyboard did not appear.");
  }
}

- (void)testTypingWordsThatTriggerAutoCorrect {
  NSString *string = @"hekp";
  [self ftr_typeString:string andVerifyOutput:string];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_clearText()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextView")]
      performAction:grey_clearText()];

  string = @"helko";
  [self ftr_typeString:string andVerifyOutput:string];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_clearText()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextView")]
      performAction:grey_clearText()];

  string = @"balk";
  [self ftr_typeString:string andVerifyOutput:string];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_clearText()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextView")]
      performAction:grey_clearText()];

  string = @"surr";
  [self ftr_typeString:string andVerifyOutput:string];
}

- (void)testNumbersTyping {
  NSString *string = @"1234567890";
  [self ftr_typeString:string andVerifyOutput:string];
}

- (void)testSymbolsTyping {
  NSString *string = @"~!@#$%^&*()_+-={}:;<>?";
  [self ftr_typeString:string andVerifyOutput:string];
}

- (void)testLetterTyping {
  NSString *string = @"aBc";
  [self ftr_typeString:string andVerifyOutput:string];
}

- (void)testEmailTyping {
  NSString *string = @"donec.metus+spam@google.com";
  [self ftr_typeString:string andVerifyOutput:string];
}

- (void)testUpperCaseLettersTyping {
  NSString *string = @"VERYLONGTEXTWITHMANYLETTERS";
  [self ftr_typeString:string andVerifyOutput:string];
}

- (void)testNumbersAndSpacesTyping {
  NSString *string = @"0 1 2 3 4 5 6 7 8 9";
  [self ftr_typeString:string andVerifyOutput:string];
}

- (void)testSymbolsAndSpacesTyping {
  NSString *string = @"[ ] # + = _ < > { }";
  [self ftr_typeString:string andVerifyOutput:string];
}

- (void)testSpaceKey {
  NSString *string = @"a b";
  [self ftr_typeString:string andVerifyOutput:string];
}

- (void)testBackspaceKey {
  NSString *string = @"ab\b";
  NSString *verificationString = @"a";
  [self ftr_typeString:string andVerifyOutput:verificationString];
}

- (void)testReturnKey {
  NSString *kbViewClassName = @"UIKeyboardImpl";
  NSString *textFieldString = @"and\n";
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_typeText(textFieldString)] assertWithMatcher:grey_text(@"and")];

  [[EarlGrey selectElementWithMatcher:grey_kindOfClassName(kbViewClassName)]
      assertWithMatcher:grey_nil()];

  NSString *string = @"and\nand";
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextView")]
      performAction:grey_typeText(string)] assertWithMatcher:grey_text(@"and\nand")];

  [[EarlGrey selectElementWithMatcher:grey_kindOfClassName(kbViewClassName)]
      assertWithMatcher:grey_notNil()];
}

- (void)testAllReturnKeyTypes {
  NSString *kbViewClassName = @"UIKeyboardImpl";
  // There are 11 returnKeyTypes; test all of them.
  for (int i = 0; i < 11; i++) {
    [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
        performAction:grey_typeText(@"a\n")] assertWithMatcher:grey_text(@"a")];

    [[EarlGrey selectElementWithMatcher:grey_kindOfClassName(kbViewClassName)]
        assertWithMatcher:grey_nil()];

    [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
        performAction:grey_typeText(@"*\n")] assertWithMatcher:grey_text(@"a*")];

    [[EarlGrey selectElementWithMatcher:grey_kindOfClassName(kbViewClassName)]
        assertWithMatcher:grey_nil()];

    [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"next returnKeyType")]
        performAction:grey_tap()];
  }
}

- (void)testPanelNavigation {
  NSString *string = @"a1a%a%1%";
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_typeText(string)];
}

- (void)testKeyplaneIsDetectedCorrectlyWhenSwitchingTextFields {
  NSString *string = @"$";

  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_typeText(string)] assertWithMatcher:grey_text(string)];

  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextView")]
      performAction:grey_typeText(string)] assertWithMatcher:grey_text(string)];
}

- (void)testUIKeyboardTypeDefault {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"KeyboardPicker")]
      performAction:[GREYActions actionForSetPickerColumn:0 toValue:@"Default"]];

  NSString *string = @":$a8. {T<b@CC";
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_typeText(string)] assertWithMatcher:grey_text(string)];
}

- (void)testUIKeyboardTypeASCIICapable {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"KeyboardPicker")]
      performAction:[GREYActions actionForSetPickerColumn:0 toValue:@"ASCIICapable"]];

  NSString *string = @":$a8. {T<b@CC";
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_typeText(string)] assertWithMatcher:grey_text(string)];
}

- (void)testUIKeyboardTypeNumbersAndPunctuation {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"KeyboardPicker")]
      performAction:[GREYActions actionForSetPickerColumn:0 toValue:@"NumbersAndPunctuation"]];

  NSString *string = @":$a8. {T<b@CC";
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_typeText(string)] assertWithMatcher:grey_text(string)];
}

- (void)testUIKeyboardTypeURL {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"KeyboardPicker")]
      performAction:[GREYActions actionForSetPickerColumn:0 toValue:@"URL"]];

  NSString *string = @"http://www.google.com/@*s$&T+t?[]#testLabel%foo;";
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_typeText(string)] assertWithMatcher:grey_text(string)];
}

- (void)testUIKeyboardTypeNumberPad {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"KeyboardPicker")]
      performAction:[GREYActions actionForSetPickerColumn:0 toValue:@"NumberPad"]];

  NSString *string = @"\b0123456\b789\b\b";
  NSString *verificationString = @"0123457";
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_typeText(string)] assertWithMatcher:grey_text(verificationString)];
}

- (void)testUIKeyboardTypePhonePad {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"KeyboardPicker")]
      performAction:[GREYActions actionForSetPickerColumn:0 toValue:@"PhonePad"]];

  NSString *string = @"01*23\b\b+45#67,89;";
  NSString *verificationString = @"01*+45#67,89;";
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_typeText(string)] assertWithMatcher:grey_text(verificationString)];
}

- (void)testUIKeyboardTypeEmailAddress {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"KeyboardPicker")]
      performAction:[GREYActions actionForSetPickerColumn:0 toValue:@"EmailAddress"]];

  NSString *string = @"l0rem.ipsum+42@google.com#$_T*-";
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_typeText(string)] assertWithMatcher:grey_text(string)];
}

- (void)testUIKeyboardTypeDecimalPad {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"KeyboardPicker")]
      performAction:[GREYActions actionForSetPickerColumn:0 toValue:@"DecimalPad"]];

  NSString *string = @"\b0123.456\b78..9\b\b";
  NSString *verificationString = @"0123.4578.";
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_typeText(string)] assertWithMatcher:grey_text(verificationString)];
}

- (void)testUIKeyboardTypeTwitter {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"KeyboardPicker")]
      performAction:[GREYActions actionForSetPickerColumn:0 toValue:@"Twitter"]];

  NSString *string = @"@earlgrey Your framework is #awesome!!!1$:,eG%g\n";
  NSString *verificationString = @"@earlgrey Your framework is #awesome!!!1$:,eG%g";
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_typeText(string)] assertWithMatcher:grey_text(verificationString)];
}

- (void)testUIKeyboardTypeWebSearch {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"KeyboardPicker")]
      performAction:[GREYActions actionForSetPickerColumn:0 toValue:@"WebSearch"]];

  NSString *string = @":$a8. {T<b@CC";
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_typeText(string)] assertWithMatcher:grey_text(string)];
}

- (void)testTypingOnLandscapeLeft {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeLeft error:nil];
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_typeText(@"Cat")] assertWithMatcher:grey_text(@"Cat")];
}

- (void)testTypingOnLandscapeRight {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeRight error:nil];
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_typeText(@"Cat")] assertWithMatcher:grey_text(@"Cat")];
}

- (void)testSuccessivelyTypingInTheSameTextField {
  [[[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_typeText(@"This ")] performAction:grey_typeText(@"Is A ")]
      performAction:grey_typeText(@"Test")] assertWithMatcher:grey_text(@"This Is A Test")];
}

- (void)testTypingBlankString {
  NSString *string = @"       ";
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_typeText(string)] assertWithMatcher:grey_text(string)];
}

- (void)testClearAfterTypingInCustomTextView {
  [[[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"CustomTextView")]
      performAction:[GREYActions actionForTypeText:@"Foo"]]
      assertWithMatcher:grey_accessibilityLabel(@"Foo")]
      performAction:[GREYActions actionForClearText]]
      assertWithMatcher:grey_accessibilityLabel(@"")];
}

- (void)testClearAfterClearingInCustomTextView {
  [[[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"CustomTextView")]
      performAction:[GREYActions actionForClearText]]
      assertWithMatcher:grey_accessibilityLabel(@"")]
      performAction:[GREYActions actionForClearText]]
      assertWithMatcher:grey_accessibilityLabel(@"")];
}

- (void)testTypeAfterClearingInCustomTextView {
  [[[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"CustomTextView")]
      performAction:[GREYActions actionForClearText]]
      assertWithMatcher:grey_accessibilityLabel(@"")]
      performAction:[GREYActions actionForTypeText:@"Foo"]]
      assertWithMatcher:grey_accessibilityLabel(@"Foo")];
}

- (void)testTypingOnTextFieldInUIInputAccessory {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"Input Button")]
      performAction:grey_tap()];
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"InputAccessoryTextField")]
      performAction:grey_typeText(@"Test")] assertWithMatcher:grey_text(@"Test")];
}

- (void)testClearAndReplaceWorksWithUIAccessibilityTextFieldElement {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"Input Button")]
      performAction:grey_tap()];

  NSString *accessibilityTextFieldElemClassName = @"UIAccessibilityTextFieldElement";
  id<GREYMatcher> elementMatcher =
      grey_allOf(grey_accessibilityValue(@"Text Field"),
                 grey_kindOfClassName(accessibilityTextFieldElemClassName), nil);
  [[[EarlGrey selectElementWithMatcher:elementMatcher] performAction:grey_clearText()]
      performAction:grey_replaceText(@"foo")];

  [[EarlGrey selectElementWithMatcher:grey_textFieldValue(@"foo")] assertWithMatcher:grey_notNil()];
}

- (void)testTypingAndResigningOfFirstResponder {
  GREYAssertFalse([GREYKeyboard isKeyboardShown], @"Keyboard Shouldn't be Shown");

  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:[GREYActions actionForTypeText:@"Foo"]] assertWithMatcher:grey_text(@"Foo")];
  GREYAssertTrue([GREYKeyboard isKeyboardShown], @"Keyboard Shouldn't be Shown");

  [EarlGrey dismissKeyboardInApplication:self.application error:nil];
  GREYAssertFalse([GREYKeyboard isKeyboardShown], @"Keyboard Shouldn't be Shown as it is resigned");

  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:[GREYActions actionForTypeText:@"Foo"]] assertWithMatcher:grey_text(@"FooFoo")];
  GREYAssertTrue([GREYKeyboard isKeyboardShown], @"Keyboard Shouldn't be Shown");
}

- (void)testTogglingShiftByChangingCase {
  NSString *multiCaseString = @"aA1a1A1aA1AaAa1A1a";
  for (NSUInteger i = 0; i < multiCaseString.length; i++) {
    NSString *currentCharacter = [multiCaseString substringWithRange:NSMakeRange(i, 1)];
    [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
        performAction:grey_typeText(currentCharacter)]
        assertWithMatcher:grey_text([multiCaseString substringToIndex:i + 1])];
    id keyboardClass = GREY_REMOTE_CLASS_IN_APP(GREYKeyboard);
    for (NSString *axLabel in [[keyboardClass returnByValue] shiftKeyLabels]) {
      NSError *error;
      [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(axLabel)] performAction:grey_tap()
                                                                                    error:&error];
    }
  }

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      assertWithMatcher:grey_text(multiCaseString)];
}

- (void)testIsKeyboardShownWithCustomKeyboardTracker {
  GREYAssertFalse([GREYKeyboard isKeyboardShown], @"Keyboard Shouldn't be Shown");

  GREYHostApplicationDistantObject *host = GREYHostApplicationDistantObject.sharedInstance;
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"CustomKeyboardTracker")]
      performAction:host.actionForSetFirstResponder];
  GREYAssertFalse([GREYKeyboard isKeyboardShown], @"Keyboard Shouldn't be Shown");
}

- (void)testTypingAndResigningWithError {
  GREYAssertFalse([GREYKeyboard isKeyboardShown], @"Keyboard Shouldn't be Shown");

  GREYHostApplicationDistantObject *host = GREYHostApplicationDistantObject.sharedInstance;
  NSError *error;
  [EarlGrey dismissKeyboardInApplication:self.application error:&error];
  NSString *localizedErrorDescription = [error localizedDescription];
  GREYAssertTrue(
      [localizedErrorDescription hasPrefix:@"Failed to dismiss keyboard since it was not showing."],
      @"Unexpected error message for initial dismiss: %@, original error: %@",
      localizedErrorDescription, error);

  [[EarlGrey selectElementWithMatcher:grey_keyWindow()]
      performAction:host.actionForSetFirstResponder
              error:&error];
  [EarlGrey dismissKeyboardInApplication:self.application error:&error];
  localizedErrorDescription = [error localizedDescription];
  GREYAssertTrue(
      [localizedErrorDescription hasPrefix:@"Failed to dismiss keyboard since it was not showing."],
      @"Unexpected error message for second dismiss: %@, original error: %@",
      localizedErrorDescription, error);
}

#pragma mark - Private

- (void)ftr_typeString:(NSString *)string andVerifyOutput:(NSString *)verificationString {
  [[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_typeText(string)] performAction:grey_typeText(@"\n")]
      assertWithMatcher:grey_text(verificationString)];
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextView")]
      performAction:grey_typeText(string)] assertWithMatcher:grey_text(verificationString)];
  [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"Done")] performAction:grey_tap()];
}

@end
