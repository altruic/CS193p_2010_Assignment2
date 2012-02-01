//
//  CalculatorBrain.m
//  Calculator
//
//  Created by Ed Sibbald on 10/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CalculatorBrain.h"


@interface CalculatorBrain()
@property (copy) NSString *waitingOperation;
@end


@implementation CalculatorBrain


@synthesize waitingOperation=internalWaitingOperation;
@synthesize operand=internalOperand;


- (id)init
{
	self = [super init];
	if (self)
		lastAction = kOperand; // not having anything is like having just added 0 as an operand
	return self;
}


- (void)saveExpressionComponent:(id)component
{
	if (!internalExpression)
		internalExpression = [[NSMutableArray alloc] init];
	[internalExpression addObject:component];
	NSLog(@"expression: %@", [CalculatorBrain descriptionOfExpression:internalExpression]);
}


- (void)setOperand:(double)anOperand
{
	if (lastAction != kBinaryOperator) {
		self.waitingOperation = nil;
		waitingOperand = 0;
	}
	internalOperand = anOperand;
	[self saveExpressionComponent:[NSNumber numberWithDouble:anOperand]];
	lastAction = kOperand;
}


- (id)expression
{
	return internalExpression ? [NSArray arrayWithArray:internalExpression] : nil;
}


- (void)performWaitingOperation
{
	if ([self.waitingOperation isEqual:@"+"])
		internalOperand = waitingOperand + internalOperand;
	else if ([self.waitingOperation isEqual:@"-"])
		internalOperand = waitingOperand - internalOperand;
	else if ([self.waitingOperation isEqual:@"*"])
		internalOperand = waitingOperand * internalOperand;
	else if ([self.waitingOperation isEqual:@"/"]) {
		if (internalOperand)
			internalOperand = waitingOperand / internalOperand;
		else
			NSLog(@"divide by 0 attempted");
	}
	// check for "=" here? return an error if the operation wasn't valid?
}


#define VARIABLE_PREFIX @"$"


- (void)setVariableAsOperand:(NSString *)variableName
{
	if (lastAction != kBinaryOperator) {
		self.waitingOperation = nil;
		waitingOperand = 0;
	}
	[self saveExpressionComponent:[VARIABLE_PREFIX stringByAppendingString:variableName]];
	lastAction = kOperand;
}


- (double)performOperation:(NSString *)operation
{
	// don't set operand through the property here because it adds the specific double value to the expression
	
	BOOL clearWaitingOperation = YES;
	BOOL saveOperationInExpression = YES;

	if ([operation isEqual:@"Store"]) {
		memory = self.operand;
		clearWaitingOperation = NO;
		// no real action here
	}
	else if ([operation isEqual:@"Mem +"]) {
		memory += self.operand;
		clearWaitingOperation = NO;
		// no real action here
	}
	else if ([operation isEqual:@"Recall"]) {
		clearWaitingOperation = YES;
		internalOperand = memory;
		lastAction = kOperand;
	}
	else if ([operation isEqual:@"sqrt"]) {
		clearWaitingOperation = (lastAction == kBinaryOperator);
		if (internalOperand > 0)
			internalOperand = sqrt(internalOperand);
		else {
			NSLog(@"sqrt attempted on negative operand %g", internalOperand);
			internalOperand = 0;
		}
		lastAction = kUnaryOperator;
	}
	else if ([operation isEqual:@"1/x"]) {
		clearWaitingOperation = (lastAction == kBinaryOperator);
		if (internalOperand)
			internalOperand = 1 / internalOperand;
		else {
			NSLog(@"1/x attemped on operand 0");
			internalOperand = 0;
		}
		lastAction = kUnaryOperator;
	}
	else if ([operation isEqual:@"sin"]) {
		clearWaitingOperation = (lastAction == kBinaryOperator);
		internalOperand = sin(internalOperand);
		lastAction = kUnaryOperator;
	}
	else if ([operation isEqual:@"cos"]) {
		clearWaitingOperation = (lastAction == kBinaryOperator);
		internalOperand = cos(internalOperand);
		lastAction = kUnaryOperator;
	}
	else if ([operation isEqual:@"+ / -"]) {
		clearWaitingOperation = (lastAction == kBinaryOperator);
		internalOperand = -internalOperand;
		lastAction = kUnaryOperator;
	}
	else if ([operation isEqual:@"C"]) {
		internalOperand = 0;
		memory = 0;
		
		[internalExpression release];
		internalExpression = nil;
		saveOperationInExpression = NO; // fixme: i don't think this is correct
		
		NSLog(@"expression cleared");
		lastAction = kOperand; // clearing is like restarting with 0 as the operand
	}
	else {
		if (lastAction != kBinaryOperator)
			[self performWaitingOperation];
		self.waitingOperation = operation;
		waitingOperand = internalOperand;
		clearWaitingOperation = NO;
		lastAction = [operation isEqual:@"="] ? kOperand : kBinaryOperator;
	}

	if (clearWaitingOperation) {
		self.waitingOperation = nil;
		waitingOperand = 0;
	}

	if (saveOperationInExpression)
		[self saveExpressionComponent:operation];
	
	return internalOperand;
}


+ (NSString *)variableNameFromString:(NSString *)aString
{
	if ([aString length] < [VARIABLE_PREFIX length])
		return nil;
	NSRange prefixRange = [aString rangeOfString:VARIABLE_PREFIX];
	if (prefixRange.location != 0)
		return nil;
	return [aString stringByReplacingCharactersInRange:prefixRange withString:@""];
}


+ (double)evaluateExpression:(id)expression usingVariableValues:(NSDictionary *)variables
{
	if (!expression)
		return 0;
	if (![expression isKindOfClass:[NSArray class]]) {
		NSLog(@"invalid expression");
		return 0;
	}
	
	CalculatorBrain* workerBrain = [[CalculatorBrain alloc] init];
	[workerBrain autorelease];
	
	NSMutableSet *binaryOperations = [NSMutableSet set];
	[binaryOperations addObject:@"+"];
	[binaryOperations addObject:@"-"];
	[binaryOperations addObject:@"*"];
	[binaryOperations addObject:@"/"];
	BOOL lastComponentWasBinaryOperation = NO;

	for (id obj in (NSArray *)expression) {
		lastComponentWasBinaryOperation = NO;
		if ([obj isKindOfClass:[NSNumber class]]) {
			workerBrain.operand = [(NSNumber *)obj doubleValue];
		}
		else if ([obj isKindOfClass:[NSString class]]) {
			NSString *stringComponent = (NSString *)obj;
			NSString *variableName = [CalculatorBrain variableNameFromString:stringComponent];
			if (variableName != nil) {
				id variableValue = [variables objectForKey:variableName];
				if (variableValue == nil) {
					NSLog(@"value for variable '%@' not found", variableName);
					return 0;
				}
				if (![variableValue isKindOfClass:[NSNumber class]]) {
					NSLog(@"value for variable '%@' was not a number", variableName);
					return 0;
				}
				workerBrain.operand = [(NSNumber *)variableValue doubleValue];
			}
			else {
				[workerBrain performOperation:stringComponent];
				if ([binaryOperations member:stringComponent])
					lastComponentWasBinaryOperation = YES;
			}
		}
		else {
			NSLog(@"expression contained unknown component '%@'", obj);
			return 0;
		}
	}
	
	if (!lastComponentWasBinaryOperation)
		[workerBrain performOperation:@"="];
	
	return workerBrain.operand;
}


+ (NSSet *)variablesInExpression:(id)expression
{
	if (!expression)
		return nil;
	if (![expression isKindOfClass:[NSArray class]]) {
		NSLog(@"invalid expression");
		return 0;
	}

	NSMutableSet *variables = [NSMutableSet set];
	for (id obj in (NSArray *)expression) {
		if ([obj isKindOfClass:[NSString class]]) {
			NSString *variableName = [CalculatorBrain variableNameFromString:(NSString *)obj];
			if (variableName != nil && ![variables member:variableName])
				[variables addObject:variableName];
		}
	}
	
	return [variables count] > 0 ? variables : nil;
}


+ (NSString *)descriptionOfExpression:(id)expression
{
	if (!expression)
		return nil;
	if (![expression isKindOfClass:[NSArray class]]) {
		NSLog(@"invalid expression");
		return @"<ERROR>";
	}

	NSMutableString* description = [NSMutableString string];

	BOOL skipFirstSpace = YES;
	for (id obj in (NSArray *)expression) {
		if (!skipFirstSpace)
			[description appendString:@" "];
		skipFirstSpace = NO;
		
		if ([obj isKindOfClass:[NSNumber class]]) {
			[description appendFormat:@"%g", [(NSNumber *)obj doubleValue]];
		}
		else if ([obj isKindOfClass:[NSString class]]) {
			NSString *stringComponent = (NSString *)obj;
			NSString *variableName = [CalculatorBrain variableNameFromString:stringComponent];
			if (variableName)
				[description appendString:variableName];
			else
				[description appendString:stringComponent];
		}
		else {
			NSLog(@"expression contained unknown component '%@'", obj);
			return @"<ERROR>";
		}
	}
	
	return [NSString stringWithString:description];
}


+ (id)propertyListForExpression:(id)expression
{
	if (!expression)
		return nil;
	if (![expression isKindOfClass:[NSArray class]]) {
		NSLog(@"invalid expression");
		return nil;
	}
	
	NSMutableArray *propertyList = [NSMutableArray array];
	for (id obj in (NSArray *)expression) {
		if ([obj isKindOfClass:[NSNumber class]] || [obj isKindOfClass:[NSString class]])
			[propertyList addObject:obj];
		else {
			NSLog(@"expression contained unknown component '%@'", obj);
			return nil;
		}
	}
	
	return [NSArray arrayWithArray:propertyList];
}


+ (id)expressionForPropertyList:(id)propertyList
{
	if (!propertyList)
		return nil;
	if (![propertyList isKindOfClass:[NSArray class]]) {
		NSLog(@"property list cannot be converted to an expression");
		return nil;
	}

	NSMutableArray *expression = [NSMutableArray array];
	for (id obj in (NSArray *)propertyList) {
		if ([obj isKindOfClass:[NSNumber class]] || [obj isKindOfClass:[NSString class]])
			[expression addObject:obj];
		else {
			NSLog(@"property list contained component that does not belong in an expression '%@'", obj);
			return nil;
		}
	}
	
	return [NSArray arrayWithArray:expression];
}


- (void)dealloc
{
	[internalWaitingOperation release];
	[internalExpression release];
	[super dealloc];
}


@end
