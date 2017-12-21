#import <UIKit/UIKit.h>

@interface WebViewDBController : UIViewController <UIWebViewDelegate, UIAlertViewDelegate> {
@private
    UIWebView *webView;
	NSString *startURL;
	NSString *returnURL;
	NSString *access_token;	
	int type;
}

@property (nonatomic, readonly) UIWebView *webView;
@property (nonatomic, retain) NSString *startURL;
@property (nonatomic, retain) NSString *returnURL;
@property (nonatomic, retain) NSString *access_token;
@property (nonatomic, readonly) UIActivityIndicatorView *loadingView;
@property (nonatomic, assign) int type;
- (id)initDropboxType:(int)type;
@end
