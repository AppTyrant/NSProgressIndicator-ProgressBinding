//
//  AppDelegate.m
//  NSProgressIndicatorNSProgressBinding
//
//  Created by ANTHONY CRUZ on 4/28/19.
//  Copyright © 2019 Writes for All. All rights reserved.
//

#import "AppDelegate.h"
#import "NSProgressIndicator+ProgressBinding.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSProgressIndicator *determinateProgressBar;
@property (weak) IBOutlet NSProgressIndicator *determinateCircularIndicator;
@property (weak) IBOutlet NSProgressIndicator *indeterminateSpinner;
@property (weak) IBOutlet NSProgressIndicator *indeterminateProgressBar;

@property (weak) IBOutlet NSProgressIndicator *syncIndeterminatePropertySpinner;
@property (weak) IBOutlet NSProgressIndicator *syncIndeterminatePropertyProgressBar;

@end

@implementation AppDelegate

-(void)applicationDidFinishLaunching:(NSNotification*)aNotification
{
    // Insert code here to initialize your application
}

-(IBAction)testDeterminateProgressBar:(NSButton*)sender
{
    sender.enabled = NO;
    
    dispatch_queue_t progressQueue = dispatch_queue_create("com.atprogTestQueue", NULL);
    NSProgress *dummmyProgress = [[NSProgress alloc]initWithParent:nil userInfo:nil];
    int64_t totalUnitCount = 100;
    dummmyProgress.totalUnitCount = totalUnitCount;
    self.determinateProgressBar.observedProgress = dummmyProgress;
    self.determinateCircularIndicator.observedProgress = dummmyProgress;
    
    dispatch_async(progressQueue, ^{
        
        int64_t compUnitCount = dummmyProgress.completedUnitCount;
        while (compUnitCount < totalUnitCount)
        {
            [NSThread sleepForTimeInterval:0.1];
            compUnitCount++;
            dummmyProgress.completedUnitCount = compUnitCount;
            
            //Uncomment below to test setting the bindedProgress property to nil halfway through progress operation.
            /*
            if (compUnitCount == 50)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"nil out progress halfway through.");
                    self.determinateProgressBar.bindedProgress = nil;
                    self.determinateCircularIndicator.bindedProgress = nil;
                });
                break;
            }
             */
        }
        
        NSLog(@"done");
        dispatch_async(dispatch_get_main_queue(), ^{
            sender.enabled = YES;
        });
        
    });
}

-(IBAction)testIndeterminateProgressIndicator:(NSButton*)sender
{
    sender.enabled = NO;
    
    dispatch_queue_t progressQueue = dispatch_queue_create("com.atprogTestQueue", NULL);
    
     NSProgress *dummmyProgress = [[NSProgress alloc]initWithParent:nil userInfo:nil];
     dummmyProgress.completedUnitCount = -1;
     dummmyProgress.totalUnitCount = 1;
     self.indeterminateSpinner.observedProgress = dummmyProgress;
     self.indeterminateProgressBar.observedProgress = dummmyProgress;
    
    dispatch_async(progressQueue, ^{
        
        [NSThread sleepForTimeInterval:5.0];
        dummmyProgress.completedUnitCount = dummmyProgress.totalUnitCount;
        
        
        NSLog(@"done");
        dispatch_async(dispatch_get_main_queue(), ^{
            sender.enabled = YES;
        });
        
    });
}

-(IBAction)testProgressThatStartsIndeterminateThenBecomesDeterminate:(NSButton*)sender
{
    sender.enabled = NO;
    
    dispatch_queue_t progressQueue = dispatch_queue_create("com.atprogTestQueue", NULL);
    
    NSProgress *dummmyProgress = [[NSProgress alloc]initWithParent:nil userInfo:nil];
    dummmyProgress.completedUnitCount = -1;
    dummmyProgress.totalUnitCount = 1;
    [self.syncIndeterminatePropertySpinner setObservedProgress:dummmyProgress syncIndeterminateProperty:YES];
    [self.syncIndeterminatePropertyProgressBar setObservedProgress:dummmyProgress syncIndeterminateProperty:YES];
    
    dispatch_async(progressQueue, ^{
        
        [NSThread sleepForTimeInterval:2.0];
        dummmyProgress.totalUnitCount = 100.0;
        dummmyProgress.completedUnitCount = 0.0;
        NSLog(@"Switched from indeterminate to determinate");
        [NSThread sleepForTimeInterval:2.0];
        
        int64_t compUnitCount = dummmyProgress.completedUnitCount;
        while (compUnitCount < dummmyProgress.totalUnitCount)
        {
            [NSThread sleepForTimeInterval:0.1];
            compUnitCount++;
            dummmyProgress.completedUnitCount = compUnitCount;
        }
        
        
        NSLog(@"done");
        dispatch_async(dispatch_get_main_queue(), ^{
            sender.enabled = YES;
        });
        
    });
}

@end
