Class {
	#name : #EvaluatorDebuggerPresenter,
	#superclass : #SpPresenter,
	#traits : 'TStDebuggerExtension',
	#classTraits : 'TStDebuggerExtension classTrait',
	#instVars : [
		'toolbar',
		'code',
		'inspector',
		'valueLabel',
		'evaluatorDebugger',
		'expressionListPresenter'
	],
	#category : #'EvaluatorDebugger-Base'
}

{ #category : #specs }
EvaluatorDebuggerPresenter class >> defaultSpec [
^ SpBoxLayout newVertical
		add: #toolbar expand: false fill: false padding: 0;
		add: #code;
		add: 'Expression Value' expand: false fill: false padding: 5;
		add: #valueLabel expand: false fill: false padding: 5;
		add: #inspector;
		add: #expressionListPresenter; 
		yourself
]

{ #category : #'accessing context' }
EvaluatorDebuggerPresenter >> currentStDebuggerContext [

	"A 'shortcut' to get the same currentContext of the StDebugger"

	^ evaluatorDebugger stDebugger currentContext
]

{ #category : #'debugger extension' }
EvaluatorDebuggerPresenter >> debuggerExtensionToolName [

	^ 'Evaluator Debugger' 
]

{ #category : #initialization }
EvaluatorDebuggerPresenter >> initializeCode [

	"We define the extensions Code presenter initialization here"

	code := self newCode.
	code interactionModel: EvaluatorDebuggerCodeInteractionModel new.
	code syntaxHighlight: true.
	code text: '"put your expression here"'
]

{ #category : #initialization }
EvaluatorDebuggerPresenter >> initializePresenters [

	"Called by the Spec framework. This method describes how the widgets are initialized"

	self initializeToolbar.
	self initializeCode.
	
	valueLabel := self newLabel.
	valueLabel label: 'Write an expression first'.
	inspector := nil inspectionRaw.
	inspector owner: self.
	expressionListPresenter := ExpressionListPresenter new. 
	expressionListPresenter listExpressions evaluationContext: self currentStDebuggerContext. 
	expressionListPresenter owner: self. 
	
	"when changing the selected context in the stDebugger stackTable, re-evaluate the expression in that context"
	evaluatorDebugger stDebugger stackTable selection whenChangedDo: [ 
		self updatePresenter ].
	self updatePresenter
]

{ #category : #initialization }
EvaluatorDebuggerPresenter >> initializeToolbar [

	toolbar := self newToolbar
		           addItem: (self newToolbarButton
				            icon: (self application iconNamed: #smallDoIt);
				            action: [ self updatePresenter ];
				            yourself);
		           yourself
]

{ #category : #'accessing model' }
EvaluatorDebuggerPresenter >> setModelBeforeInitialization: aStDebugger [

	"This method is called when the StDebugger initializes its extensions. We initialize our model (the debugger extension) with a reference to the stDebugger."

	evaluatorDebugger := EvaluatorDebugger new.
	evaluatorDebugger stDebugger: aStDebugger
]

{ #category : #updating }
EvaluatorDebuggerPresenter >> updateCode [

	"Sets the context of our debugger-extension code presenter to be the same one of the StDebugger"

	code interactionModel context: self currentStDebuggerContext
]

{ #category : #'as yet unclassified' }
EvaluatorDebuggerPresenter >> updateExpressionListContext [

	expressionListPresenter listExpressions evaluationContext: self currentStDebuggerContext. 
	expressionListPresenter listExpressions expressionList do:[ :e| e autoEvaluate ifTrue:[ expressionListPresenter listExpressions evaluateExpression:e] ]. 
	expressionListPresenter updateView. 

]

{ #category : #updating }
EvaluatorDebuggerPresenter >> updateExpressionValueDisplayed [

	"Evaluate the expression, in the code presenter, using the appropriate context (the current one of the stDebgger). Then update the ui to show and inspect the obtained value, or a potential exception."

	| expressionBlock expressionResult errorFlag errorMessage |
	expressionBlock := [ 
	                   evaluatorDebugger
		                   evaluateInCurrentContextExpression:
		                   code text readStream
		                   withRequestor: code interactionModel ].
	errorFlag := false.
	expressionResult := expressionBlock
		                    on: Exception
		                    do: [ :e | 
			                    errorFlag := true.
			                    errorMessage := e description.
			                    e ].
	"The inspector shows the result object in case of success, or the Exception otherwise"
	inspector model: expressionResult.
	valueLabel label: (errorFlag
			 ifTrue: [ errorMessage ]
			 ifFalse: [ expressionResult asString ])
]

{ #category : #initialization }
EvaluatorDebuggerPresenter >> updatePresenter [

	self updateCode.
	self updateExpressionListContext. 
	self updateExpressionValueDisplayed. 
	super updatePresenter
]
