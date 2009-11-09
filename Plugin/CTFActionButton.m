//
//  CTFActionButton.m
//  ClickToFlash
//
//  Created by  Sven on 09.10.09.
//  Copyright 2009 earthlingsoft. All rights reserved.
//

#import "CTFActionButton.h"
#import "CTFUtilities.h"

static CGFloat padding = 3.;


@implementation CTFActionButton

+ (id) actionButton {
	CGFloat margin = 5.;
	CGFloat size = 20.;
	NSRect gearButtonRect = NSMakeRect( .0, .0, size + 2.*margin , size + 2.*margin );

	CTFActionButton * gearButton = [[[CTFActionButton alloc] initWithFrame: gearButtonRect] autorelease];
	[gearButton setButtonType: NSMomentaryPushInButton];
	
	return gearButton;
}



#pragma mark NSButton subclassing

+ (Class) cellClass {
	return NSClassFromString(@"CTFActionButtonCell");
}



- (void) mouseDown: (NSEvent *) event {
	[NSMenu popUpContextMenu:[self menuForEvent:event] withEvent:event forView:self];
}	



- (NSMenu*) menuForEvent: (NSEvent*) event {
	return [[self superview] menuForEvent: event];
}



- (void) resizeWithOldSuperviewSize:(NSSize) oldBoundsSize {
	NSPoint newOrigin;
	
	if ( [[self cell ] gearVisible] ) {
		NSSize superSize = [[self superview] bounds].size;
		NSRect myRect = [self bounds];
		newOrigin = NSMakePoint(myRect.origin.x, superSize.height - myRect.size.height);
	}
	else {
		newOrigin = NSMakePoint( -1000. , -1000. );
	}
	
	[self setFrameOrigin: newOrigin];
}


@end






#pragma mark -
#pragma mark NSView subclassing



@implementation CTFActionButtonCell

#pragma mark NSCell subclassing

- (void) drawWithFrame: (NSRect) rect inView:(NSView *) controlView {
	NSRect bounds = [[self controlView] bounds];
			
	NSImage * gearImage = [NSImage imageNamed:@"NSActionTemplate"];
	// On systems older than 10.5 we need to supply our own image.
	if (gearImage == nil) {
		NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"NSActionTemplate" ofType:@"png"];
		gearImage = [[[NSImage alloc] initWithContentsOfFile:path] autorelease];
	}
			
	if( gearImage ) {
		CGFloat gearSize = [gearImage size].width; // assumes the gear to be square
		CGFloat size = gearSize + 2.0 * padding;
		CGFloat x = round(bounds.size.width * .5) - round(size * .5);
		CGFloat y = round(bounds.size.height * .5 ) - round(size * .5);										
		NSRect backgroundFrame = NSMakeRect(x, y, size, size);
		
		NSBezierPath * circle = [NSBezierPath bezierPathWithOvalInRect:backgroundFrame];
		CGFloat alpha = ( [self isHighlighted] ) ? .9 : .7 ;
		[[NSColor colorWithDeviceWhite:1.0 alpha:alpha] set];
		[circle fill];
				
		// draw the gear image
		[gearImage drawAtPoint:NSMakePoint(x + padding, y + padding)
					  fromRect:NSZeroRect
					 operation:NSCompositeSourceOver
					  fraction:.9];
	}
}




#pragma mark -
#pragma mark Helper

- (BOOL) gearVisible {
	NSRect bounds = [[[self controlView] superview] bounds ];
	return NSWidth( bounds ) > 32 && NSHeight( bounds ) > 32;
}





#pragma mark -
#pragma mark Accessibility

- (NSArray *) accessibilityAttributeNames {
	NSMutableArray * attributes = [[[super accessibilityAttributeNames] mutableCopy] autorelease];
	[attributes addObject: NSAccessibilityDescriptionAttribute];
	return attributes;
}



- (id) accessibilityAttributeValue: (NSString *) attribute {
	id value;
	
	if ( [attribute isEqualToString: NSAccessibilityDescriptionAttribute] ) {
		value = CtFLocalizedString( @"ClickTo Flash Contextual menu", @"Accessibility: CTFActionButton, Title of Contextual Menu");
	}
	else if ( [attribute isEqualToString: NSAccessibilityParentAttribute] ){
		value = NSAccessibilityUnignoredAncestor([[self controlView] superview]); 
	}
	else {
		value = [super accessibilityAttributeValue:attribute];
	}
	return value;
}


@end
