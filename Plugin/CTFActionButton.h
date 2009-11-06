//
//  CTFActionButton.h
//  ClickToFlash
//
//  Created by  Sven on 09.10.09.
//  Copyright 2009 earthlingsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>




@interface CTFActionButton : NSButton {
}

+ (id) actionButton;

@end


@interface CTFActionButtonCell : NSButtonCell {
	
}

- (BOOL) gearVisible;

@end