#import "NonceSet.h"
#import "WebViewDBController.h"
#import <CommonCrypto/CommonDigest.h>
#import <notify.h>
OBJC_EXTERN CFStringRef MGCopyAnswer(CFStringRef key) WEAK_IMPORT_ATTRIBUTE;

static __strong NSString* oauth_consumer_key = @"3wg57gho3rco3lb";

@implementation WebViewDBController

@synthesize webView, startURL, returnURL, access_token, type;
@dynamic loadingView;

- (id)initDropboxType:(int)typenew
{
    if (self = [super init]) {
		self.access_token = nil;
		self.type = typenew;
		self.returnURL = [[@"db-" stringByAppendingString:oauth_consumer_key] stringByAppendingString:@"://2/token"];
		self.startURL = [NSString stringWithFormat:@"https://www.dropbox.com/1/oauth2/authorize?response_type=token&client_id=%@&redirect_uri=%@&disable_signup=true", oauth_consumer_key, self.returnURL];
    }
    return self;
}
- (void)loadLogin
{
	[webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:startURL]]];
}
- (void)showAlertManager
{
	if(self.access_token && self.access_token.length > 0) {
		if(type == 1) {
			[self showAlertManagerBackup];
		} else if(type == 2) {
			[self showAlertManagerSource];
		}
	} else {
		[self loadLogin];
	}
}
- (void)showAlertManagerSource
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Save/Restore Backups Online (Dropbox)" message:@"Choose Action\n\nNote: Upload Backups to Dropbox will replace existing Backups file on account." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Download Backups To This Device", @"Upload Backups Of This Device To Dropbox", @"Logout Account", nil];
	alert.tag = 1;
	[alert show];
}

- (void)showAlertManagerBackup
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Save/Restore Backups Online (Dropbox)" message:@"Choose Action\n\nNote: Upload Backups to Dropbox will replace existing Backups file on account." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Download Backups To This Device", @"Upload Backups Of This Device To Dropbox", @"Logout Account", nil];
	alert.tag = 1;
	[alert show];
}
- (void)saveTokens
{
	if(!self.access_token) {
		return;
	}
	@autoreleasepool {
		[[NSUserDefaults standardUserDefaults] setObject:[self.access_token dataUsingEncoding:NSUTF8StringEncoding] forKey:@"db-access_token"];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
}
- (void)loadView
{
	[super loadView];
	webView = [[UIWebView alloc] initWithFrame:CGRectZero];
	webView.delegate = self;
	self.view = webView;
	NSData* credData = [[NSUserDefaults standardUserDefaults] objectForKey:@"db-access_token"]?:nil;
	if(credData) {
		self.access_token = [[NSString alloc] initWithData:credData encoding:NSUTF8StringEncoding];
	}
	[self showAlertManager];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(Reload)];
	self.navigationItem.rightBarButtonItems = @[button];
}

#define LOADING_TAG 6543
-(UIActivityIndicatorView *)loadingView
{
	UIActivityIndicatorView *lv = (UIActivityIndicatorView *)[self.view viewWithTag:LOADING_TAG];
	if (lv == nil) {
		lv = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		[lv setHidesWhenStopped:TRUE];
		lv.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.6f];
		[lv setColor:[UIColor whiteColor]];
		lv.layer.cornerRadius = 05;
		lv.opaque = NO;
		lv.center = self.view.center;
		lv.tag = LOADING_TAG;
		[self.view addSubview:lv];
	}
	return lv;
}

-(void)Reload
{
	[webView reload];
}
-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self loadingView];
}
-(void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}
- (void)dealloc
{
	self.startURL = nil;
	self.returnURL = nil;
	if(self.view && [self.view respondsToSelector:@selector(delegate)]) {
		((UIWebView *)self.view).delegate = nil;
	}
}



- (void)receiveURLToken:(NSString*)URLToken
{
	NSURL* urlTK = [NSURL URLWithString:URLToken];
	NSString* queryst = [urlTK fragment];
	if(!queryst) {
		return;
	}
	NSMutableDictionary *queryStringDictionary = [[NSMutableDictionary alloc] init];
	NSArray *urlComponents = [queryst componentsSeparatedByString:@"&"];
	for (NSString *keyValuePair in urlComponents) {
		NSArray *pairComponents = [keyValuePair componentsSeparatedByString:@"="];
		NSString *key = [[pairComponents firstObject] stringByRemovingPercentEncoding];
		NSString *value = [[pairComponents lastObject] stringByRemovingPercentEncoding];
		[queryStringDictionary setObject:value forKey:key];
	}
	self.access_token = [queryStringDictionary objectForKey:@"access_token"]?:self.access_token;
	[self saveTokens];
	[self showAlertManager];	
}

- (void)showError:(NSString*)error
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:error delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
}
- (NSMutableURLRequest*)downloadRequest:(NSString*)file
{
	NSString* url_reqA = [[@"https://api-content.dropbox.com/2" stringByAppendingPathComponent:@"files"] stringByAppendingPathComponent:@"download"];
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setURL:[NSURL URLWithString:url_reqA]];
	[request setHTTPMethod:@"POST"];
	[request setValue:[NSString stringWithFormat:@"Bearer %@", self.access_token] forHTTPHeaderField:@"Authorization"];
	[request setValue:[NSString stringWithFormat:@"{\"path\":\"%@\"}", file] forHTTPHeaderField:@"Dropbox-API-Arg"];
	return request;
}
- (NSMutableURLRequest*)uploadRequest:(NSString*)file
{
	NSString* url_reqA = [[@"https://api-content.dropbox.com/2" stringByAppendingPathComponent:@"files"] stringByAppendingPathComponent:@"upload"];
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setURL:[NSURL URLWithString:url_reqA]];
	[request setHTTPMethod:@"POST"];
	[request setValue:[NSString stringWithFormat:@"Bearer %@", self.access_token] forHTTPHeaderField:@"Authorization"];
	[request setValue:[NSString stringWithFormat:@"{\"path\":\"%@\",\"autorename\":false,\"mute\":false,\"mode\":{\".tag\":\"overwrite\"}}", file] forHTTPHeaderField:@"Dropbox-API-Arg"];
	[request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
	return request;
}
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if(buttonIndex == [alertView cancelButtonIndex]) {
		return;
	}
	NSString* buttonTitle = [[alertView buttonTitleAtIndex:buttonIndex] copy];
	
	if (alertView.tag == 1 && [buttonTitle isEqualToString:@"Logout Account"]) {
		@autoreleasepool {
			[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"db-access_token"];
			[[NSUserDefaults standardUserDefaults] synchronize];
		}
    } else if (alertView.tag == 1 && buttonIndex == 1) {//Download Backup
        NSMutableURLRequest* request = [self downloadRequest:[NSString stringWithFormat:@"/nonceset_%@.plist", (__bridge NSString *)MGCopyAnswer(CFSTR("UniqueChipID"))]];
		NSError* error = nil;
		NSURLResponse* imageresponse_link = nil;
		NSHTTPURLResponse *httpResponse_link = nil;
		NSData *imageresult_link = [NSURLConnection sendSynchronousRequest:request returningResponse:&imageresponse_link error:&error];
		httpResponse_link = (NSHTTPURLResponse*)imageresponse_link;
		if(error) {
			[self showError:[error localizedDescription]];
			if((httpResponse_link && httpResponse_link.statusCode == 401) || (error.code == kCFURLErrorUserCancelledAuthentication)) {
				[self loadLogin];
				return;
			} else {				
				return;
			}
		}		
		if (httpResponse_link.statusCode == 200 && imageresult_link) {
			
			[[NonceSetController shared] setNonceValue:[[NSString alloc] initWithData:imageresult_link encoding:NSUTF8StringEncoding] specifier:nil];
			
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Save/Restore Backups Online (Dropbox)" message:@"Backups Downloaded From Dropbox To This Device With Success." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];		
		} else if (httpResponse_link.statusCode == 404) {
			[self showError:@"Backups File Not Found In This Dropbox Account."];
			return;
		} else {
			[self showError:@"Unknown Error"];
			return;
		}		
    } else if (alertView.tag == 1 && buttonIndex == 2) {//Upload Backup
		NSMutableURLRequest* request = [self uploadRequest:[NSString stringWithFormat:@"/nonceset_%@.plist", (__bridge NSString *)MGCopyAnswer(CFSTR("UniqueChipID"))]];
		NSString* currentBootNonce = [[NonceSetController shared] readNonceValue:nil];
		NSData *fileData = nil;
		if(currentBootNonce && currentBootNonce.length > 0) {
			fileData = [currentBootNonce dataUsingEncoding:NSUTF8StringEncoding];
			[request setHTTPBody:fileData];
		} else {
			[self showError:@"No Backups Found On This Device."];
			return;
		}
		NSError* error = nil;
		NSURLResponse* imageresponse_link = nil;
		NSHTTPURLResponse* httpResponse_link = nil;
		NSData* imageresult_link = [NSURLConnection sendSynchronousRequest:request returningResponse:&imageresponse_link error:&error];
		httpResponse_link = (NSHTTPURLResponse*)imageresponse_link;
		if(error) {
			[self showError:[error localizedDescription]];
			if((httpResponse_link && httpResponse_link.statusCode == 401) || (error.code == kCFURLErrorUserCancelledAuthentication)) {
				[self loadLogin];
				return;
			} else {				
				return;
			}
		}
		if (httpResponse_link.statusCode == 200) {
			NSDictionary *json_imageresult_link = [NSJSONSerialization JSONObjectWithData:imageresult_link options:kNilOptions error:&error];
			if(json_imageresult_link) {
				if(fileData && [[json_imageresult_link objectForKey:@"size"]?:@(0) intValue] == fileData.length) {
					UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Save/Restore Backups Online (Dropbox)" message:@"Backups Of This Device Uploaded To Dropbox With Success." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
					[alert show];
				}
			}
		} else {
			[self showError:@"Unknown Error"];
			return;
		}		
    }
	[self.navigationController popViewControllerAnimated:TRUE];
}

#pragma mark UIWebViewDelegate methods
- (BOOL)webView:(UIWebView *)webViewA shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	NSString *urlString = [[request.URL absoluteString] lowercaseString];
	if (urlString && urlString.length>0) {
		if ([urlString hasPrefix:[returnURL lowercaseString]]) {
			[self receiveURLToken:[request.URL absoluteString]];
			return FALSE;
		}
	}
	return TRUE;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	self.title = [[[NSBundle mainBundle] localizedStringForKey:@"LOADING" value:@"Loading" table:nil] stringByAppendingString:@"..."];
	[self.loadingView startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webViewA
{
	self.title = [webViewA stringByEvaluatingJavaScriptFromString:@"document.title"];
	[self.loadingView stopAnimating];
	if([webViewA stringByEvaluatingJavaScriptFromString:@"document.getElementsByClassName('app-name')[0].innerHTML = \"NonceSet\";"] != nil) {
		//
	}
	if([webViewA stringByEvaluatingJavaScriptFromString:@"document.getElementById('app-icon').src = \"https://i.imgur.com/bl8y1Xi.png\";"] != nil) {
		//
	}
}


- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	[self.loadingView stopAnimating];
	if(error.code == 102) {
		return;
	}
	[self.navigationController popViewControllerAnimated:TRUE];
	self.title = @"Connection failed";
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection failed" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
}
@end
