//
//  CalculatorViewController.m
//  Calculator
//
//  Created by Ed Sibbald on 10/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CalculatorViewController.h"
#include <stdlib.h>


@implementation CalculatorViewController

@synthesize display;


- (void)viewDidLoad
{
	brain = [[CalculatorBrain alloc] init];
}


- (IBAction)digitPressed:(UIButton *)sender
{
	NSString* digit = sender.titleLabel.text;
	
	if (userIsTypingANumber)
		display.text = [display.text stringByAppendingString:digit];
	else {
		display.text = digit;
		userIsTypingANumber = YES;
	}
}


- (IBAction)operationPressed:(UIButton *)sender
{
	if (userIsTypingANumber) {
		brain.operand = [display.text doubleValue];
		userIsTypingANumber = NO;
	}
	NSString *operation = sender.titleLabel.text;
	double result = [brain performOperation:operation];
	id expression = brain.expression;
	if ([CalculatorBrain variablesInExpression:expression])
		display.text = [CalculatorBrain descriptionOfExpression:expression];
	else
		display.text = [NSString stringWithFormat:@"%g", result];
}


- (IBAction)variablePressed:(UIButton *)sender
{
	// it doesn't make any sense to type a variable right after a number, but our brain should handle it gracefully.
	if (userIsTypingANumber) {
		brain.operand = [display.text doubleValue];
		userIsTypingANumber = NO;
	}
	[brain setVariableAsOperand:sender.titleLabel.text];
	display.text = [CalculatorBrain descriptionOfExpression:brain.expression];
}


- (IBAction)decimalPointPressed
{
	if (userIsTypingANumber) {
		NSRange range = [display.text rangeOfString:@"."];
		if (range.location == NSNotFound)
			display.text = [display.text stringByAppendingString:@"."];
	}
	else {
		display.text = @"0.";
		userIsTypingANumber = YES;
	}
}


- (IBAction)solvePressed
{
	if (userIsTypingANumber) {
		brain.operand = [display.text doubleValue];
		userIsTypingANumber = NO;
	}

	id expression = brain.expression;
	NSSet *variableSet = [CalculatorBrain variablesInExpression:expression];
	NSMutableDictionary *variableDict = nil;
	if (variableSet) {
		variableDict = [NSMutableDictionary dictionary];
		for (NSString* variable in variableSet) {
			int randomInt = arc4random() % 1000;
			[variableDict setObject:[NSNumber numberWithInt:randomInt] forKey:variable];
		}
	}
	double result = [CalculatorBrain evaluateExpression:expression
									usingVariableValues:variableDict];
	display.text = [NSString stringWithFormat:@"%g", result];
}


- (void)releaseOutlets
{
	self.display = nil;
}


- (void)viewDidUnload
{
	[self releaseOutlets];
}


- (void)dealloc
{
	[brain release];
	[self releaseOutlets];
	[super dealloc];
}


@end
