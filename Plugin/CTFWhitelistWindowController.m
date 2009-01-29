#import "CTFWhitelistWindowController.h"


@implementation CTFWhitelistWindowController

- (id)init
{
    NSBundle * myBundle = [NSBundle bundleForClass:[self class]];
    NSString * nibPath = [myBundle pathForResource:@"WhitelistPanel" ofType:@"nib"];
    if (nibPath == nil)
    {
        [self dealloc];
        return nil;
    }
    
    self = [super initWithWindowNibPath:nibPath owner:self];
    return self;
}

@end
