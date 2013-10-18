//
//  DCRoundSwitchKnobLayer.m
//
//  Created by Patrick Richards on 29/06/11.
//  MIT License.
//
//  http://twitter.com/patr
//  http://domesticcat.com.au/projects
//  http://github.com/domesticcatsoftware/DCRoundSwitch
//

#import "DCRoundSwitchKnobLayer.h"

CGGradientRef CreateGradientRefWithColors(CGColorSpaceRef colorSpace, CGColorRef startColor, CGColorRef endColor);

@implementation DCRoundSwitchKnobLayer
@synthesize gripped;

UIColor *knobStartColor = nil;
UIColor *knobEndColor   = nil;

- (void)drawInContext:(CGContextRef)context
{
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
	CGRect knobRect = CGRectInset(self.bounds, 2, 2);
	CGFloat knobRadius = self.bounds.size.height - 2;

	// knob outline (shadow is drawn in the toggle layer)
	CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:0.62 alpha:1.0].CGColor);
	CGContextSetLineWidth(context, 1.5);
	CGContextStrokeEllipseInRect(context, knobRect);
	CGContextSetShadowWithColor(context, CGSizeMake(0, 0), 0, NULL);

	// knob inner gradient
	CGContextAddEllipseInRect(context, knobRect);
	CGContextClip(context);
  
	knobStartColor = [UIColor colorWithWhite:0.82 alpha:1.0];
	knobEndColor = (self.gripped) ? [UIColor colorWithWhite:0.894 alpha:1.0] : [UIColor colorWithWhite:0.996 alpha:1.0];
  
	CGPoint topPoint = CGPointMake(0, 0);
	CGPoint bottomPoint = CGPointMake(0, knobRadius + 2);
  
  // PDS: Awful crash fix follows..
	//CGGradientRef knobGradient = CreateGradientRefWithColors(colorSpace, knobStartColor, knobEndColor);
  
  NSArray *colors = [NSArray arrayWithObjects:(__bridge id)knobStartColor.CGColor, (__bridge id) knobEndColor.CGColor, nil];
  CGFloat colorStops[2] = {0.0, 1.0};
  CGGradientRef knobGradient =  CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef) colors, colorStops );
 
  
	CGContextDrawLinearGradient(context, knobGradient, topPoint, bottomPoint, 0);
	CGGradientRelease(knobGradient);

	// knob inner highlight
	CGContextAddEllipseInRect(context, CGRectInset(knobRect, 0.5, 0.5));
	CGContextAddEllipseInRect(context, CGRectInset(knobRect, 1.5, 1.5));
	CGContextEOClip(context);

  // PDS: Awful crash fix follows..
	//CGGradientRef knobHighlightGradient = CreateGradientRefWithColors(colorSpace, [UIColor whiteColor].CGColor, [UIColor colorWithWhite:1.0 alpha:0.5].CGColor);
  
  NSArray *colors2 = [NSArray arrayWithObjects:(__bridge id)[UIColor whiteColor].CGColor, (__bridge id) [UIColor colorWithWhite:1.0 alpha:0.5].CGColor, nil];
  CGGradientRef knobHighlightGradient =  CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef) colors2, colorStops );
  
  
  
	CGContextDrawLinearGradient(context, knobHighlightGradient, topPoint, bottomPoint, 0);
	CGGradientRelease(knobHighlightGradient);

	CGColorSpaceRelease(colorSpace);
}

/*
CGGradientRef CreateGradientRefWithColors(CGColorSpaceRef colorSpace, CGColorRef startColor, CGColorRef endColor)
{
  CGFloat colorStops[2] = {0.0, 1.0};
  
  
  NSArray *colors = [NSArray arrayWithObjects:(__bridge id) startColor, (__bridge id) endColor, nil];
  
  CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colors, colorStops);
  
  return gradient;
}
*/

/*
- (void)drawInContext:(CGContextRef)context
{
  UIColor *startColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
  UIColor *endColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
  
  NSArray *colors = [NSArray arrayWithObjects:(__bridge id)startColor.CGColor, (__bridge id) endColor.CGColor, nil];
  
  CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef) colors, locations);
}
 */

/*
CGGradientRef CreateGradientRefWithColors(CGColorSpaceRef colorSpace, CGColorRef startColor, CGColorRef endColor)
{
	CGFloat colorStops[2] = {0.0, 1.0};
	CGColorRef colors[ 2 ] = {startColor, endColor};
  
  int x =  sizeof(colors) / sizeof(CGColorRef);
  
	CFArrayRef colorsArray = CFArrayCreate( NULL, (const void**)colors, x, &kCFTypeArrayCallBacks);
  
	CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, colorsArray, colorStops);
  
	CFRelease(colorsArray);
	return gradient;
}
*/

- (void)setGripped:(BOOL)newGripped
{
	gripped = newGripped;
	[self setNeedsDisplay];
}

@end
