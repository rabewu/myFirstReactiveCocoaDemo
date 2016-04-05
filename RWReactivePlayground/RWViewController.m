//
//  RWViewController.m
//  RWReactivePlayground
//
//  Created by Colin Eberhardt on 18/12/2013.
//  Copyright (c) 2013 Colin Eberhardt. All rights reserved.
//

#import "RWDummySignInService.h"
#import "RWViewController.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface RWViewController ()

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (weak, nonatomic) IBOutlet UILabel *signInFailureText;

@property (strong, nonatomic) RWDummySignInService *signInService;

@end

@implementation RWViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.signInService = [RWDummySignInService new];

    // initially hide the failure message
    self.signInFailureText.hidden = YES;
    
    // 用户名信号
    RACSignal *validUsernameSignal =
    [self.usernameTextField.rac_textSignal
     map:^id(NSString *text) {
        return @([self isValidPassword:text]);
    }];
    // 密码信号
    RACSignal *validPasswordSignal =
    [self.passwordTextField.rac_textSignal
     map:^id(NSString *text) {
        return @([self isValidPassword:text]);
    }];
    
    // 将用户名信号传到map管道事件中然后返回值作为usernameTextField的backgroundColor属性
    RAC(self.usernameTextField, backgroundColor) =
    [validUsernameSignal
     map:^id(NSNumber *usernameValid){
         return[usernameValid boolValue] ? [UIColor clearColor] : [UIColor yellowColor];
     }];
    
    // 同上,此处RAC为宏
    RAC(self.passwordTextField, backgroundColor) =
    [validPasswordSignal
     map:^id(NSNumber *passwordValid) {
        return passwordValid.boolValue ? [UIColor clearColor] : [UIColor yellowColor];
    }];
    
    // 登录按钮是否可用信号
    RACSignal *signUpActiveSignal =
    [RACSignal combineLatest:@[validPasswordSignal, validPasswordSignal]
                      reduce:^id(NSNumber *usernameValid, NSNumber *passwordValid){
        return @(usernameValid.boolValue && passwordValid.boolValue);
    }];
    
    // 将信号与按钮绑定
    [signUpActiveSignal subscribeNext:^(NSNumber *signUpActive) {
        self.signInButton.enabled = signUpActive.boolValue;
    }];
    
    [[[[self.signInButton
        rac_signalForControlEvents:UIControlEventTouchUpInside]
       doNext:^(id x) {
          self.signInButton.enabled = NO;
          self.signInFailureText.hidden = YES;
      }]
      flattenMap:^id(id value) {
        return [self signInSignal];
    }]
     subscribeNext:^(NSNumber *signedIn) {
        self.signInButton.enabled = YES;
        BOOL success = [signedIn boolValue];
        self.signInFailureText.hidden = success;
        if (success) {
            [self performSegueWithIdentifier:@"signInSuccess" sender:self];
        }
    }];
}

- (BOOL)isValidUsername:(NSString *)username
{
    return username.length > 3;
}

- (BOOL)isValidPassword:(NSString *)password
{
    return password.length > 3;
}

- (RACSignal *)signInSignal
{
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [self.signInService signInWithUsername:self.usernameTextField.text password:self.passwordTextField.text complete:^(BOOL success) {
            [subscriber sendNext:@(success)];
            [subscriber sendCompleted];
        }];
        return nil;
    }];
}

@end
