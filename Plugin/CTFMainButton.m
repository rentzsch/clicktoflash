//
//  CTFMainButton.m
//  ClickToFlash
//
//  Created by  Sven on 10.10.09.
//  Copyright 2009 earthlingsoft. All rights reserved.
//

#import "CTFMainButton.h"
#import "CTFGradient.h"
#import "Plugin.h"
#import "CTFUtilities.h"
#import "NSBezierPath-RoundedRectangle.h"



@implementation CTFMainButton

+ (Class) cellClass {
	return NSClassFromString(@"CTFMainButtonCell");
}


- (BOOL) isFlipped {
	return NO;
}


- (NSMenu*) menuForEvent: (NSEvent*) event {
	return [[self superview] menuForEvent: event];
}

@end






#pragma mark -

@implementation CTFMainButtonCell


#pragma mark NSCell subclassing

- (void) drawWithFrame: (NSRect) rect inView:(NSView *) controlView {
	NSRect bounds = [[self controlView] bounds];
	NSRect fillRect   = NSInsetRect(bounds, 1.0, 1.0);
    
	[self drawGradientInRect: fillRect];
	[self drawPreviewInRect: fillRect];
	
    // Draw stroke
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.50] set];
    [NSBezierPath setDefaultLineWidth:2.0];
    [NSBezierPath setDefaultLineCapStyle:NSSquareLineCapStyle];
    [[NSBezierPath bezierPathWithRect:bounds] stroke];
	
    // Draw label
    [self drawBadgeForBounds: bounds];
    
	// Draw 'glossy' overlay which can give some visual feedback on clicks when an preview image is set.
	if ([(CTFClickToFlashPlugin*)[controlView superview] previewImage] != nil) {
		[self drawGlossForBounds: bounds];		
	}
	
}



#pragma mark -
#pragma mark Drawing

- (void) drawGradientInRect: (NSRect) rect {
    NSColor *startingColor = [NSColor colorWithDeviceWhite: 1.0 alpha: 0.15];
    NSColor *endingColor = [NSColor colorWithDeviceWhite: 0.0 alpha: 0.15];
	
    // When the view is 'On', use a convex look: draw the gradient downwards (90+180=270 degrees).
    // When the view is 'Off' use a concave look: draw the gradient upwards (90 degrees).
	CGFloat angle;
	if ( [self isHighlighted] ) {
		angle = 90.;
	}
	else {
		angle = 270.;
	}
	
	NSBezierPath * rectPath = [NSBezierPath bezierPathWithRect:rect];
	id gradient = [NSClassFromString(@"NSGradient") alloc];
	
	if (gradient != nil) {
        gradient = [gradient initWithStartingColor:startingColor endingColor:endingColor];
        [gradient drawInBezierPath:rectPath angle:angle];
		
        [gradient release];
    }
    else {
		//tweak the opacity of the endingColor for compatibility with CTGradient
		endingColor = [NSColor colorWithDeviceWhite:0.0 alpha:0.00];
		
		gradient = [CTFGradient gradientWithBeginningColor:startingColor endingColor:endingColor];
		
		//angle is reversed compared to NSGradient
		[gradient fillBezierPath:rectPath angle:-angle];
	}
}


- (void) drawPreviewInRect: (NSRect) rect {
	// Overlay the preview image if there is one
	NSImage * image = [(CTFClickToFlashPlugin*) [[self controlView] superview] previewImage];

	if ( image != nil ) {
		// Determine the destination rect. The approach is to scale the preview image until it fills the view horizontally. This risks losing pixels at the top and bottom but seems to match what the sites providing preview images do for widescreen movies, thus giving better results than 'clean' scaling to fit the whole image inside the view.
		NSRect destinationRect;
		NSSize imageSize = [image size];
		CGFloat scale = rect.size.width / imageSize.width;
		CGFloat destinationWidth = imageSize.width * scale;
		CGFloat destinationHeight = imageSize.height * scale;
		CGFloat destinationBottom = rect.origin.y + ( rect.size.height - destinationHeight) / 2.0;
		
		destinationRect = NSMakeRect(rect.origin.x, destinationBottom, destinationWidth, destinationHeight);
		
		[image drawInRect:destinationRect fromRect:NSZeroRect operation:NSCompositeSourceIn fraction: 0.8];
	}
}




- (NSString*) badgeLabelText
{
	NSString * labelText = nil;
	CTFKiller * killer = [(CTFClickToFlashPlugin*)[[self controlView] superview] killer];
	
	
	if (killer != nil) {
		labelText = [killer badgeLabelText];
	}
	
	if (labelText == nil) {
		labelText = CtFLocalizedString( @"Flash", @"Flash badge text" );
	}
	
	return labelText;
}



- (void) drawBadgeForBounds: (NSRect) bounds {	
	static BOOL _fromFlickr = NO;  // have to figure this out

	// What and how are we going to draw?
	const float kFrameXInset = 10;
	const float kFrameYInset =  4;
	const float kMinMargin   = 11;
	const float kMinHeight   =  6;
	
	NSString* str = [ self badgeLabelText ];
	
	NSShadow *superAwesomeShadow = [[NSShadow alloc] init];
	[superAwesomeShadow setShadowOffset:NSMakeSize(2.0, -2.0)];
	[superAwesomeShadow setShadowColor:[NSColor whiteColor]];
	[superAwesomeShadow autorelease];
	NSDictionary* attrs = [ NSDictionary dictionaryWithObjectsAndKeys: 
						   [ NSFont boldSystemFontOfSize: 20 ], NSFontAttributeName,
						   [ NSNumber numberWithInt: -1 ], NSKernAttributeName,
						   [ NSColor blackColor ], NSForegroundColorAttributeName,
						   superAwesomeShadow, NSShadowAttributeName,
						   nil ];
	
	// How large would this text be?
	
	NSSize strSize = [ str sizeWithAttributes: attrs ];
	
	float w = strSize.width  + kFrameXInset * 2;
	float h = strSize.height + kFrameYInset * 2;
	
	// Compute a scale factor based on the view's size.
	
	float maxW = NSWidth( bounds ) - kMinMargin;
	// the 9/10 factor here is to account for the 60% vertical top-biasing
	float maxH = _fromFlickr ? NSHeight( bounds )*9/10 - kMinMargin : NSHeight( bounds ) - kMinMargin;
	float minW = kMinHeight * w / h;
	
	BOOL rotate = NO;
	if( maxW <= minW )	// too narrow in width, so rotate it
		rotate = YES;
	
	if( rotate ) {		// swap the dimensions to scale into
		float temp = maxW;
		maxW = maxH;
		maxH = temp;
	}
	
	if( maxH <= kMinHeight ) {
		// Too short in height for full margin.
		
		// Draw at the smallest size, with less margin,
		// unless even that would get clipped off.
		
		if( maxH + kMinMargin < kMinHeight )
			return;
        
		maxH = kMinHeight;
	}
	
	float scaleFactor = 1.0;
	
	if( maxW < w )
		scaleFactor = maxW / w;
    
	if( maxH < h && maxH / h < scaleFactor )
		scaleFactor = maxH / h;
	
	// Apply the scale, and a transform so the result is centered in the view.
	
	[ NSGraphicsContext saveGraphicsState ];
    
	NSAffineTransform* xform = [ NSAffineTransform transform ];
	// vertical top-bias by 60% here
    if (_fromFlickr) {
        [ xform translateXBy: NSWidth( bounds ) / 2 yBy: NSHeight( bounds ) / 10 * 6 ];
    } else {
        [ xform translateXBy: NSWidth( bounds ) / 2 yBy: NSHeight( bounds ) / 2 ];
    }

	[ xform scaleBy: scaleFactor ];
	if( rotate )
		[ xform rotateByDegrees: 90 ];
	[ xform concat ];
	
    CGContextRef context = [ [ NSGraphicsContext currentContext ] graphicsPort ];
    
	CGFloat opacity = 0.45;
	// Make Badge more opaque when we have a background image
	if ( [(CTFClickToFlashPlugin*) [[self controlView] superview] previewImage] != nil ) {
		opacity = 0.8;
	}
	
	CGContextSetAlpha( context, ( [self isHighlighted] ) ? opacity : opacity - 0.15 );		
	CGContextBeginTransparencyLayer( context, nil );
	
	// Draw everything at full size, centered on the origin.
	
	NSPoint loc = { -strSize.width / 2, -strSize.height / 2 };
	NSRect borderRect = NSMakeRect( loc.x - kFrameXInset, loc.y - kFrameYInset, w, h );
	
    NSBezierPath* fillPath = bezierPathWithRoundedRectCornerRadius( borderRect, 4 );
    [ [ NSColor colorWithCalibratedWhite: 1.0 alpha: opacity ] set ];
    [ fillPath fill ];
    
    NSBezierPath* darkBorderPath = bezierPathWithRoundedRectCornerRadius( borderRect, 4 );
    [[NSColor blackColor] set];
    [ darkBorderPath setLineWidth: 3 ];
    [ darkBorderPath stroke ];
    
    NSBezierPath* lightBorderPath = bezierPathWithRoundedRectCornerRadius( NSInsetRect(borderRect, -2, -2), 6 );
    [ [ NSColor colorWithCalibratedWhite: 1.0 alpha: opacity ] set ];
    [ lightBorderPath setLineWidth: 2 ];
    [ lightBorderPath stroke ];
    
    [ str drawAtPoint: loc withAttributes: attrs ];
	
	// Now restore the graphics state:
	CGContextEndTransparencyLayer( context );
    [NSGraphicsContext restoreGraphicsState ];
}



- (void) drawGlossForBounds: (NSRect) bounds {
	NSBezierPath * bP = [NSBezierPath bezierPath];
	const CGFloat glowStartFraction = .3;
	const CGFloat cP1YFraction = .5;
	const CGFloat cP2XFraction = .0;
	const CGFloat cP2YFraction = .48;
	
	CGFloat startY = .0;
	if ([self isHighlighted]) {
		startY = NSMaxY(bounds);
	}
	
	[bP moveToPoint: NSMakePoint( .0, startY ) ];
	[bP lineToPoint: NSMakePoint( .0, NSMaxY(bounds) * glowStartFraction )];
	[bP curveToPoint: NSMakePoint( NSMidX(bounds), NSMidY(bounds) )
	   controlPoint1: NSMakePoint( .0 , cP1YFraction * NSMaxY(bounds))
	   controlPoint2: NSMakePoint( cP2XFraction * NSMaxX(bounds), cP2YFraction * NSMaxY(bounds)) ];
	[bP curveToPoint: NSMakePoint( NSMaxX(bounds), (1. - glowStartFraction) * NSMaxY(bounds) )
	   controlPoint1: NSMakePoint( (1. - cP2XFraction) * NSMaxX(bounds) , (1. - cP2YFraction) * NSMaxY(bounds) ) 
	   controlPoint2: NSMakePoint( NSMaxX(bounds), (1. - cP1YFraction) * NSMaxY(bounds) ) ];
	[bP lineToPoint: NSMakePoint( NSMaxX(bounds), startY ) ];
	[bP closePath];
	
	[[NSColor colorWithCalibratedWhite:1.0 alpha:0.07] set];
	[bP fill];
}




#pragma mark -
#pragma mark Helper

- (BOOL) gearVisibleInView: (NSView *) view {
	NSRect bounds = [view bounds];
	return NSWidth( bounds ) > 32 && NSHeight( bounds ) > 32;
}



#pragma mark -
#pragma mark Accessibility

- (BOOL)accessibilityIsIgnored {
	return NO;
}



- (NSArray *) accessibilityAttributeNames {
	NSMutableArray * attributes = [[[super accessibilityAttributeNames] mutableCopy] autorelease];
	[attributes addObject: NSAccessibilityTitleAttribute];
	[attributes addObject: NSAccessibilityDescriptionAttribute];
	return attributes;
}



- (id) accessibilityAttributeValue: (NSString *) attribute {
	id value = nil;
	
	if ( [attribute isEqualToString: NSAccessibilityTitleAttribute] ) {
		value = [self badgeLabelText];
	}
	else if ( [attribute isEqualToString: NSAccessibilityDescriptionAttribute] ) {
		value = CtFLocalizedString( @"Load Flash Content", @"NSAccessibilityDescriptionAttribute for CTFMainButton");
	}
	else if ( [attribute isEqualToString: NSAccessibilityParentAttribute] ){
		value = NSAccessibilityUnignoredAncestor([[self controlView] superview]); 
	}
	else if ( [attribute isEqualToString: NSAccessibilityRoleAttribute] ) {
		value = NSAccessibilityButtonRole;
	}
	else if ( [attribute isEqualToString: NSAccessibilityRoleDescriptionAttribute] ) {
		value = NSAccessibilityRoleDescription(NSAccessibilityButtonRole, nil);
	}
	else {
		value =  [super accessibilityAttributeValue:attribute];
	}
	
	return value;
}



 - (NSArray *) accessibilityActionNames {
	 NSArray * actionNames = [NSArray arrayWithObjects: NSAccessibilityPressAction, NSAccessibilityShowMenuAction, nil];
	 return actionNames;
 }
 
 /*
 - (void) accessibilityPerformAction: (NSString *) action {
	 if ( [action isEqualToString: NSAccessibilityPressAction] ) {
		 [self convertTypesForContainer];
	 }
	 
	 else {
		 [super accessibilityPerformAction: action];
	 }
 }
*/






@end
