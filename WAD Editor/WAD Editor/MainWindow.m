//
//  MainWindow.m
//  WAD Editor
//
//  Created by Евгений Лютц on 16.12.2019.
//  Copyright © 2019 Eugene Lutz. All rights reserved.
//

#import "MainWindow.h"
#import "WadKitView.h"
#include "wad_kit_link.h"

@interface MainWindow()
@property (weak) IBOutlet WadKitView* wadKitView;
@end

@implementation MainWindow
{
	WAD* wad;
}

- (void)initializeWithMetalDevice:(id<MTLDevice>)device
{
	if (!device)
	{
		NSArray<__kindof NSView*>* subviews = self.contentView.subviews.copy;
		for (NSView* view in subviews)
		{
			[view removeFromSuperview];
		}
		
		NSTextField* text = [[NSTextField alloc] init];
		text.font = [NSFont systemFontOfSize:32.0f weight:NSFontWeightBold];
		text.stringValue = @"Metal is not available\n on this device";
		text.alignment = NSTextAlignmentCenter;
		text.bezeled = NO;
		text.selectable = NO;
		text.editable = NO;
		text.drawsBackground = NO;
		
		[self.contentView addSubview:text];
		text.translatesAutoresizingMaskIntoConstraints = NO;
		[text.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor].active = YES;
		[text.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor].active = YES;
		
		[text.topAnchor constraintGreaterThanOrEqualToAnchor:self.contentView.topAnchor].active = YES;
		[text.bottomAnchor constraintLessThanOrEqualToAnchor:self.contentView.bottomAnchor].active = YES;
		
		[text.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.contentView.leadingAnchor].active = YES;
		[text.trailingAnchor constraintLessThanOrEqualToAnchor:self.contentView.trailingAnchor].active = YES;
		
		return;
	}
	
	wad = NULL;
	
	WadKitView* wkView = _wadKitView;
	wkView.device = device;
	wkView.delegate = nil;
}

- (IBAction)loadTestData:(id)sender
{
	if (wad)
	{
		wadRelease(wad);
	}
	
	NSString* path = [NSBundle.mainBundle pathForResource:@"tut1" ofType:@"WAD"];
	NSData* wadData = [NSData dataWithContentsOfFile:path];
	if (!wadData)
	{
		NSLog(@"Failed to read wad file");
		return;
	}
	
	EXECUTE_RESULT executeResult;
	wad = wadLoadFromWadData(wadData.bytes, wadData.length, &executeResult);
	if (!executeResult.succeeded)
	{
		NSLog(@"Failed to read wad file with message: %s", executeResult.message);
		return;
	}
	
	// display something
}

@end