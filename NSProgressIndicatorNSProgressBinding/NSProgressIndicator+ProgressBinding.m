//
//  NSProgressIndicator+ProgressBinding.m
//  NSProgressIndicatorNSProgressBinding
//
//  Created by ANTHONY CRUZ on 4/28/19.
//  Copyright © 2019 Writes for All. All rights reserved.
//
//Permission is hereby granted, free of charge, to any person obtaining a copy  of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//-The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//-THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "NSProgressIndicator+ProgressBinding.h"

@interface ATNSProgressIndicatorTracker : NSObject

@property (strong,nonatomic) NSProgress *progress;
//Weak reference to avoid retain cycle.
@property (weak) NSProgressIndicator *progressIndicator;

@property BOOL syncIndeterminatePropertyWithProgress;

@end

@implementation ATNSProgressIndicatorTracker

-(instancetype)initWithProgressIndicator:(NSProgressIndicator*)progressIndicator
{
    self = [super init];
    if (self)
    {
        _progressIndicator = progressIndicator;
    }
    return self;
}

-(void)setProgress:(NSProgress*)progress
{
    if (_progress != progress)
    {
        if (_progress != nil)
        {
            [_progress removeObserver:self forKeyPath:@"indeterminate"];
            [_progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
            [_progress removeObserver:self forKeyPath:@"finished"];
        }
        
        _progress = progress;
        
        [progress addObserver:self
                   forKeyPath:@"indeterminate"
                      options:NSKeyValueObservingOptionNew
                      context:nil];
        [progress addObserver:self
                   forKeyPath:NSStringFromSelector(@selector(fractionCompleted))
                      options:NSKeyValueObservingOptionNew
                      context:nil];
        [progress addObserver:self
                   forKeyPath:@"finished"
                      options:NSKeyValueObservingOptionNew
                      context:nil];
        
    }
}

#pragma mark - KVO
-(void)observeValueForKeyPath:(NSString*)keyPath
                     ofObject:(id)object
                       change:(NSDictionary<NSKeyValueChangeKey,id>*)change
                      context:(void*)context
{
    if (object == self.progress)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
             [self _doSyncProgressIndicatorWithProgress];
        });
    }
    else
    {
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}

#pragma mark - Sync
-(void)_doSyncProgressIndicatorWithProgress
{
    if (self.progress == nil)
    {
        [self.progressIndicator stopAnimation:nil];
        self.progressIndicator.doubleValue = 0.0;
        return;
    }
    
    BOOL isIndeterminate;
    
    if (self.syncIndeterminatePropertyWithProgress)
    {
        isIndeterminate = self.progress.isIndeterminate;
        self.progressIndicator.indeterminate = isIndeterminate;
    }
    else
    {
        isIndeterminate = self.progressIndicator.isIndeterminate;
    }
    
    if (isIndeterminate)
    {
        //For an indeterminate progress, start/stop animation based on the value of the isFinished property.
        if (self.progress.isFinished)
        {
            [self.progressIndicator stopAnimation:nil];
        }
        else
        {
            [self.progressIndicator startAnimation:nil];
        }
    }
    else
    {
        self.progressIndicator.minValue = 0.0;
        self.progressIndicator.maxValue = 1.0;
        self.progressIndicator.doubleValue = self.progress.fractionCompleted;
    }
    
}

#pragma mark - Dealloc
-(void)dealloc
{
    //NSLog(@"Dealloc called.");
    [_progress removeObserver:self forKeyPath:@"indeterminate"];
    [_progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
    [_progress removeObserver:self forKeyPath:@"finished"];
}

@end

#import <objc/runtime.h>

@implementation NSProgressIndicator (ProgressBinding)

static char const * const TheProgressKeyBinderKey = "TheProgressKey";

-(ATNSProgressIndicatorTracker*)progressTracker
{
    return objc_getAssociatedObject(self, TheProgressKeyBinderKey);
}

-(void)setProgressTracker:(ATNSProgressIndicatorTracker*)progressTracker
{
    objc_setAssociatedObject(self,
                             TheProgressKeyBinderKey,
                             progressTracker,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(NSProgress*)observedProgress
{
    return self.progressTracker.progress;
}

-(void)setObservedProgress:(NSProgress*)progressToBind syncIndeterminateProperty:(BOOL)syncIndeterminateProperty
{
    if (self.progressTracker == nil) { self.progressTracker = [[ATNSProgressIndicatorTracker alloc]initWithProgressIndicator:self]; }
    self.progressTracker.progress = progressToBind;
    self.progressTracker.syncIndeterminatePropertyWithProgress = syncIndeterminateProperty;
    [self.progressTracker _doSyncProgressIndicatorWithProgress];
}

-(void)setObservedProgress:(NSProgress*)progress
{
    [self setObservedProgress:progress syncIndeterminateProperty:self.syncIndeterminatePropertyWithObservedProgress];
}

-(BOOL)syncIndeterminatePropertyWithObservedProgress
{
    return self.progressTracker.syncIndeterminatePropertyWithProgress;
}

@end
