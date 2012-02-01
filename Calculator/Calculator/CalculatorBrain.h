//
//  CalculatorBrain.h
//  Calculator
//
//  Created by Ed Sibbald on 10/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
	kOperand,
	kUnaryOperator,
	kBinaryOperator,
} LastActionType;

@interface CalculatorBrain : NSObject {
    double internalOperand;
	NSString *internalWaitingOperation;
	double waitingOperand;
	double memory;
	NSMutableArray *internalExpression;
	LastActionType lastAction;
}

@property (nonatomic) double operand;

- (void)setVariableAsOperand:(NSString*)variableName;
- (double)performOperation:(NSString*)operation;

@property (readonly) id expression;

+ (double)evaluateExpression:(id)expression
		usingVariableValues:(NSDictionary*)variables;

+ (NSSet*)variablesInExpression:(id)expression;
+ (NSString*)descriptionOfExpression:(id)expression;

+ (id)propertyListForExpression:(id)expression;
+ (id)expressionForPropertyList:(id)propertyList;

@end
