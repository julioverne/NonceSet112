#import <dlfcn.h>
#import <objc/runtime.h>
#import <sys/stat.h>
#import <Social/Social.h>
#import <Foundation/NSTask.h>
#import <prefs.h>

@interface NonceSetController : PSListController
+ (NonceSetController*)shared;
- (void)setNonceValue:(id)value specifier:(PSSpecifier *)specifier;
- (id)readNonceValue:(PSSpecifier*)specifier;
@end

@interface NonceSetApplication : UIApplication <UIApplicationDelegate> {
	UIWindow *_window;
	UIViewController *_viewController;
}
@property (nonatomic, retain) UIWindow *window;
@end

@interface UIProgressHUD : UIView
- (void) showInView:(UIView *)view;
- (void) setText:(NSString *)text;
- (void) done;
- (void) hide;
@end

