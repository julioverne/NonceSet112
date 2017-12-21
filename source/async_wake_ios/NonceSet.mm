#include <stdio.h>
#include <IOKit/IOKitLib.h>

extern "C" {
#include "kmem.h"
#include "fun.h"
#include "async_wake.h"
}
#import "NonceSet.h"

#import "WebViewDBController.h"
#include "WebViewDBController.m"

static UITextView* textview;
static NSString* logText;

void textLog(const char *message, ...)
{
	size_t size = 500;
    char * result = (char *)malloc(size);
    while (1) {
        va_list ap;
        va_start(ap, message);
        size_t used = vsnprintf(result, size, message, ap);
        va_end(ap);
        char * newptr = (char *)realloc(result, size);
        if (!newptr) { // error
            free(result);
        }
        result = newptr;
        if (used <= size) {
			break;
		}
        size = used;
    }
	logText = [logText?:@"" stringByAppendingFormat:@"%s\n", result];
	//[[NSNotificationCenter defaultCenter] postNotificationName:@"com.julioverne.nonceset.update" object:nil];
}

@implementation NonceSetApplication
@synthesize window = _window;
- (void)applicationDidFinishLaunching:(UIApplication *)application
{
	_window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	_viewController = [[UINavigationController alloc] initWithRootViewController:[NonceSetController shared]];
	[_window addSubview:_viewController.view];
	_window.rootViewController = _viewController;
	[_window makeKeyAndVisible];
}
@end




bool set_generator(const char *gen)
{
    bool ret = false;
    CFStringRef str = CFStringCreateWithCStringNoCopy(NULL, gen, kCFStringEncodingUTF8, kCFAllocatorNull);
    CFMutableDictionaryRef dict = CFDictionaryCreateMutable(NULL, 0, &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    if(!str || !dict) {
        textLog("Failed to allocate CF objects.");
    } else {
        CFDictionarySetValue(dict, CFSTR("com.apple.System.boot-nonce"), str);
        CFRelease(str);
        io_service_t nvram = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IODTNVRAM"));
        if(!MACH_PORT_VALID(nvram)) {
            textLog("Failed to get IODTNVRAM service.");
        } else {
			kern_return_t kret = IORegistryEntrySetCFProperties(nvram, dict);
			textLog([NSString stringWithFormat:@"IORegistryEntrySetCFProperties: %s.", mach_error_string(kret)].UTF8String);
			if(kret == KERN_SUCCESS) {
				ret = true;
				textLog("Generator Set.");
			}
        }
        CFRelease(dict);
    }
    return ret;
}




static __strong NonceSetController* NonceSetControllerCC;
@implementation NonceSetController
+ (NonceSetController*)shared
{
	if(!NonceSetControllerCC) {
		NonceSetControllerCC = [[[self class] alloc] init];
	}
	return NonceSetControllerCC;
}
- (id)specifiers {
	if (!_specifiers) {
		NSMutableArray* specifiers = [NSMutableArray array];
		PSSpecifier* spec;
		
		spec = [PSSpecifier preferenceSpecifierNamed:@"Status"
						      target:self
											  set:Nil
											  get:Nil
					      detail:Nil
											  cell:PSGroupCell
											  edit:Nil];
		[spec setProperty:@"Status" forKey:@"label"];
		[specifiers addObject:spec];
		spec = [PSSpecifier preferenceSpecifierNamed:@"Root Status"
					      target:self
						 set:NULL
						 get:@selector(isRoot:)
					      detail:Nil
						cell:PSTitleValueCell
						edit:Nil];
		[specifiers addObject:spec];
		spec = [PSSpecifier preferenceSpecifierNamed:@"Logs"
					      target:self
						 set:NULL
						 get:NULL
					      detail:Nil
						cell:PSTitleValueCell
						edit:Nil];
		[spec setProperty:@"Logs" forKey:@"key"];
		[spec setProperty:@"" forKey:@"default"];
		[specifiers addObject:spec];
		
		
		spec = [PSSpecifier preferenceSpecifierNamed:@"Current Nonce"
						      target:self
											  set:Nil
											  get:Nil
					      detail:Nil
											  cell:PSGroupCell
											  edit:Nil];
		[spec setProperty:@"Current Nonce" forKey:@"label"];
		[spec setProperty:@"Current com.apple.System.boot-nonce in nvram." forKey:@"footerText"];
		[specifiers addObject:spec];
		spec = [PSSpecifier preferenceSpecifierNamed:@"boot-nonce"
					      target:self
						 set:NULL
						 get:@selector(readNonceValue:)
					      detail:Nil
						cell:PSTitleValueCell
						edit:Nil];
		[spec setProperty:@"boot-nonce" forKey:@"key"];
		[spec setProperty:@"" forKey:@"default"];
		[specifiers addObject:spec];
		
		spec = [PSSpecifier preferenceSpecifierNamed:@"Set/Change Nonce"
						      target:self
											  set:Nil
											  get:Nil
					      detail:Nil
											  cell:PSGroupCell
											  edit:Nil];
		[spec setProperty:@"Set/Change Nonce" forKey:@"label"];
		[spec setProperty:@"Nonce is set via nvram command." forKey:@"footerText"];
		[specifiers addObject:spec];
		spec = [PSSpecifier preferenceSpecifierNamed:@"boot-nonce:"
					      target:self
											  set:@selector(setNonceValue:specifier:)
											  get:@selector(readValue:)
					      detail:Nil
											  cell:PSEditTextCell
											  edit:Nil];
		[spec setProperty:@"NonceSet" forKey:@"key"];
		[specifiers addObject:spec];
		
		spec = [PSSpecifier preferenceSpecifierNamed:@"Dropbox"
						      target:self
											  set:Nil
											  get:Nil
					      detail:Nil
											  cell:PSGroupCell
											  edit:Nil];
		[spec setProperty:@"Dropbox" forKey:@"label"];
		[spec setProperty:@"You can restore your boot-nonce from Dropbox Account after a full restore of your Device." forKey:@"footerText"];
		[specifiers addObject:spec];
		spec = [PSSpecifier preferenceSpecifierNamed:@"Save/Restore Now"
					      target:self
						 set:NULL
						 get:NULL
					      detail:Nil
						cell:PSButtonCell
						edit:Nil];
		spec->action = @selector(pushDropBox);
		[spec setProperty:NSClassFromString(@"SSTintedCell") forKey:@"cellClass"];
		[specifiers addObject:spec];
		
		spec = [PSSpecifier preferenceSpecifierNamed:@"ECID"
		                                      target:self
											  set:Nil
											  get:Nil
                                              detail:Nil
											  cell:PSGroupCell
											  edit:Nil];
		[spec setProperty:@"ECID" forKey:@"label"];
		[specifiers addObject:spec];
		spec = [PSSpecifier preferenceSpecifierNamed:@"Decimal"
					      target:self
						 set:NULL
						 get:@selector(ecidValue:)
					      detail:Nil
						cell:PSTitleValueCell
						edit:Nil];
		[specifiers addObject:spec];
		spec = [PSSpecifier preferenceSpecifierNamed:@"Hexadecimal"
					      target:self
						 set:NULL
						 get:@selector(ecidHexValue:)
					      detail:Nil
						cell:PSTitleValueCell
						edit:Nil];
		[specifiers addObject:spec];
		
		spec = [PSSpecifier emptyGroupSpecifier];
        [spec setProperty:@"\n\nCREDITS:\n\nIts based in NonceSet, async_awake-fun and stek29/unlocknvram\n\nLinks:\n\nhttps://github.com/julioverne/NonceSet\n\nhttps://github.com/ninjaprawn/async_awake-fun\n\nhttps://gist.github.com/stek29/1aabf7b576332941ae5c6f81407145a3\n\n\nTested/Developed In iPhone 5S iOS 11.2.1\n\n" forKey:@"footerText"];
        [specifiers addObject:spec];
		
		spec = [PSSpecifier emptyGroupSpecifier];
        [spec setProperty:@"NonceSet112 © 2017 julioverne" forKey:@"footerText"];
        [specifiers addObject:spec];
		_specifiers = [specifiers copy];
	}
	return _specifiers;
}


- (id)isRoot:(PSSpecifier*)specifier
{
	return [NSString stringWithFormat:@"%@", getuid()==0?@"YES":@"Please Wait.."];
}

- (id)ecidValue:(PSSpecifier*)specifier
{
	return [NSString stringWithFormat:@"%@", (__bridge NSString *)MGCopyAnswer(CFSTR("UniqueChipID"))];
}
- (id)ecidHexValue:(PSSpecifier*)specifier
{
	return [NSString stringWithFormat:@"%lX", (unsigned long)[[self ecidValue:nil] integerValue]];
}
- (void)refresh:(UIRefreshControl *)refresh
{
	[self reloadSpecifiers];
	if(refresh) {
		[refresh endRefreshing];
	}	
}
- (void)showErrorFormat
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:self.title message:@"Nonce has wrong format.\n\nFormat accept:\n0xabcdef1234567890" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
}
- (void)setNonceValue:(id)value specifier:(PSSpecifier *)specifier
{
	@autoreleasepool {
		if(getuid()) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:self.title message:@"getuid() != 0" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
			return;
		}
		if(value&&[value length]>0) {
			value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			NSError *error = NULL;
			NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"0x[0-9a-f]{%@}", @([value length]-2)] options:0 error:&error];
			NSUInteger numberOfMatches = [regex numberOfMatchesInString:value options:0 range:NSMakeRange(0, [value length])];
			if(!error && numberOfMatches > 0) {
				[self setGenerator:value];
				NSString* nonce = [self readNonceValue:nil];
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:self.title message:[NSString stringWithFormat:(nonce&&[value isEqualToString:nonce])?@"Nonce (%@) has been successfully set.":@"Error in set Nonce (%@).", value] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
			} else {
				[self showErrorFormat];
			}
		} else {
			[self showErrorFormat];
		}
		[self refresh:nil];
	}
}
- (id)readValue:(PSSpecifier*)specifier
{
	return nil;
}
- (id)readNonceValue:(PSSpecifier*)specifier
{
	@autoreleasepool {
		return [self getGenerator];
	}
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	@autoreleasepool {
		system("nvram -d com.apple.System.boot-nonce");
		NSString* nonce = [self readNonceValue:nil];
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:self.title message:([nonce length] < 2)?@"Nonce has been deleted successfully.":@"Error in delete Nonce." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		[self refresh:nil];
	}
}

- (void)_returnKeyPressed:(id)arg1
{
	[super _returnKeyPressed:arg1];
	[self.view endEditing:YES];
}

- (void) loadView
{
	[super loadView];
	self.title = @"NonceSet112";
	static __strong UIRefreshControl *refreshControl;
	if(!refreshControl) {
		refreshControl = [[UIRefreshControl alloc] init];
		[refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
		refreshControl.tag = 8654;
	}	
	if(UITableView* tableV = (UITableView *)object_getIvar(self, class_getInstanceVariable([self class], "_table"))) {
		if(UIView* rem = [tableV viewWithTag:8654]) {
			[rem removeFromSuperview];
		}
		[tableV addSubview:refreshControl];
	}
	
	//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateSysLog) name:@"com.julioverne.nonceset.update" object:nil];
	
	textview = [[UITextView alloc]initWithFrame:self.view.bounds];
	[textview setScrollEnabled:YES];
	[textview setBackgroundColor:[UIColor clearColor]];
	textview.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
	textLog("\n\n\n\n");
	textLog("Getting root...");
	
	[NSTimer scheduledTimerWithTimeInterval:0.3f 
                  target:self 
                  selector:@selector(updateSysLog) 
                  userInfo:nil 
                  repeats:YES];
}

- (void)updateSysLog
{
	static int oldLen;
	if(oldLen==logText.length) {
		return;
	}
	[textview setText:logText];
	oldLen = textview.text.length;
	[textview scrollRangeToVisible:NSMakeRange(oldLen -1, 1)];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	
	[self getRoot];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.section==0 && indexPath.row==1) {
		
		UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Logs"];
		cell.textLabel.text = nil;
		cell.textLabel.textColor = [UIColor whiteColor];
		textview.frame = cell.bounds;
		textview.tag = 468;
		if(UIView* removeOld = [cell viewWithTag:468]) {
			[removeOld removeFromSuperview];
		}
		[cell addSubview:textview];
		return cell;
	}
	return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}
	
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.section==0 && indexPath.row==1) {
		return 100.0f;
	}
	return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (void)setGenerator:(NSString*)gen
{
	if(set_generator(gen.UTF8String) == true) {
		textLog("Current Generator: %s", [self getGenerator].UTF8String);
	} else {
		textLog("Generator error.");
	}
}

- (void)getRoot
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		mach_port_t user_client;
		mach_port_t tfp0 = get_tfp0(&user_client);
		let_the_fun_begin(tfp0, user_client);
		textLog("Getting root... Done.");
		textLog("Current Generator: %s", [self getGenerator].UTF8String);
		[self reloadSpecifiers];
	});
}

- (NSString *)getGenerator
{
    NSString *bootNonce = [[NSMutableString alloc] initWithString:@""];
	if(getuid()) {
		return bootNonce;
	}
    CFMutableDictionaryRef bdict = IOServiceMatching("IODTNVRAM");
    io_service_t nvservice = IOServiceGetMatchingService(kIOMasterPortDefault, bdict);
    if(MACH_PORT_VALID(nvservice)) {
        io_string_t buffer;
        unsigned int len = 256;
        kern_return_t kret = IORegistryEntryGetProperty(nvservice, "com.apple.System.boot-nonce", buffer, &len);
        if(kret == KERN_SUCCESS) {
            bootNonce = [NSString stringWithFormat:@"%s", (char *) buffer];
        } else {
            textLog("Reading com.apple.System.boot-nonce failed.");
        }
    } else {
        textLog("Failed to get IODTNVRAM.");
    }
    return bootNonce;
}

- (void)pushDropBox
{
	@try {
		[self.navigationController pushViewController:[[WebViewDBController alloc] initDropboxType:2] animated:YES];
	} @catch (NSException * e) {
	}
}
- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self refresh:nil];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath 
{
	return (indexPath.section == 1);
}
- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}
- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    return (action == @selector(copy:));
}
- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (action == @selector(copy:)) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
        [pasteBoard setString:cell.textLabel.text];
    }
}				
@end

