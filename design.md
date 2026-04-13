以下是用 CUE 语言对 Swift 部分语法的完整描述设计，展示了 CUE 在类型约束、结构复用、默认值及严谨嵌套方面的优势。

cue
// ------------------------------------------------------------
// 基础定义：词法 & 复用结构
// ------------------------------------------------------------
package swift

// Token 基础类型
#Token: {
	kind: "token"
	token?: string   // 固定文本，如 "func"
	pattern?: string // 正则模式，如标识符
}

#Identifier: #Token & {
	kind:   "token"
	pattern: "^`?[a-zA-Z_][a-zA-Z0-9_]*`?$"
	description: """
		普通标识符或反引号包裹的关键字。
		若使用反引号，内部必须为 Swift 关键字。
		"""
	examples: ["myVar", "`class`"]
}

// 类型标注 ": Type"
#TypeAnnotation: {
	colon: ":"
	type:  #Type
}

// ------------------------------------------------------------
// 类型系统（递归定义，使用闭包 #Type）
// ------------------------------------------------------------
#Type: {
	// 通过 oneOf 表示多种可能
	oneOf: [
		#SimpleTypeIdentifier,
		#OptionalType,
		#FunctionType,
		#TupleType,
		// ... 其他类型
	]
}

#SimpleTypeIdentifier: {
	kind: "type"
	name: #Identifier
	genericArguments?: {
		"<": "<"
		types: [...#Type] & {separator: ","}
		">": ">"
	}
}

#OptionalType: {
	kind: "type"
	base: #Type
	"?":  "?"
}

#FunctionType: {
	kind: "type"
	"(":      "("
	params:   #TupleTypeElementList
	")":      ")"
	"->":     "->"
	returnType: #Type
	throws?:   "throws" | "rethrows"
	async?:    "async"
}

#TupleTypeElementList: {
	// 简化：元素列表
	elements: [...{
		name?:    #Identifier
		type:     #Type
	}] & {separator: ","}
}

// ------------------------------------------------------------
// 模式匹配
// ------------------------------------------------------------
#Pattern: {
	oneOf: [
		#IdentifierPattern,
		#WildcardPattern,
		#ValueBindingPattern,
		// ...
	]
}

#IdentifierPattern: {
	kind: "pattern"
	name: #Identifier
}

#WildcardPattern: {
	kind:  "pattern"
	token: "_"
}

#ValueBindingPattern: {
	kind: "pattern"
	binding: "let" | "var"
	pattern: #Pattern
}

// ------------------------------------------------------------
// 表达式（抽象占位）
// ------------------------------------------------------------
#Expression: {
	kind: "expr"
	// 具体子类在此省略
}

// ------------------------------------------------------------
// 语句与代码块
// ------------------------------------------------------------
#CodeBlock: {
	kind: "block"
	"{":   "{"
	stmts: [...#Statement]
	"}":   "}"
}

#Statement: {
	oneOf: [
		#ExpressionStatement,
		#Declaration,       // 局部声明
		#IfStatement,
		#GuardStatement,
		// ...
	]
}

#ExpressionStatement: {
	kind: "stmt"
	expr: #Expression
}

// ------------------------------------------------------------
// 条件列表（用于 if / guard / while）
// ------------------------------------------------------------
#ConditionList: {
	conditions: [...{
		oneOf: [
			#Expression,
			#AvailabilityCondition,
			#CaseCondition,
			#OptionalBindingCondition,
		]
	}] & {separator: ","}
}

#OptionalBindingCondition: {
	kind: "condition"
	binding: "let" | "var"
	pattern: #Pattern
	"=":     "="
	init:    #Expression
	constraint: "init 类型必须为 Optional<T>"
}

#AvailabilityCondition: {
	// 例如 @available 条件
	kind: "condition"
	// 具体结构略
}

#CaseCondition: {
	// case 模式匹配条件
	kind: "condition"
	// 具体结构略
}

// ------------------------------------------------------------
// 分支语句：if / guard
// ------------------------------------------------------------
#IfStatement: {
	kind: "stmt"
	"if": "if"
	cond: #ConditionList
	body: #CodeBlock
	else?: #ElseClause
}

#ElseClause: {
	"else": "else"
	body:   #CodeBlock | #IfStatement   // 支持 else if
}

#GuardStatement: {
	kind: "stmt"
	"guard": "guard"
	cond:   #ConditionList
	"else": "else"
	body:   #CodeBlock
	constraint: "else 子句必须退出当前作用域 (return/throw/break/continue)"
}

// ------------------------------------------------------------
// 函数声明（完整版）
// ------------------------------------------------------------
#FunctionDeclaration: {
	kind: "decl"
	attrs?: [...#Attribute]
	mods?:  [...#Modifier]
	"func": "func"
	name:   #Identifier
	generics?: #GenericParameterClause
	sig: #FunctionSignature
	where?: #GenericWhereClause
	body?:  #CodeBlock

	// 作用域描述（CUE 可结构化表示）
	scope: {
		introduces: [name, ...sig.params[*].internalName]
	}
	constraints: [
		"mutating 仅允许在 struct/enum 实例方法中",
		"throws 与 rethrows 互斥",
	]
}

#FunctionSignature: {
	params: #ParameterClause
	effects?: {
		async?:  "async"
		throws?: "throws" | "rethrows"
	}
	result?: {
		"->": "->"
		type:  #Type
	}
}

#ParameterClause: {
	"(":     "("
	params:  [...#Parameter] & {separator: ","}
	")":     ")"
}

#Parameter: {
	external?: #Identifier   // 外部参数名
	local:     #Identifier   // 内部参数名
	":":       ":"
	type:      #Type
	default?: {
		"=":  "="
		expr: #Expression
	}
}

#GenericParameterClause: {
	"<":      "<"
	params:   [...#GenericParameter] & {separator: ","}
	">":      ">"
}

#GenericParameter: {
	name:      #Identifier
	conforms?: #Type   // 类型约束
}

#GenericWhereClause: {
	"where": "where"
	reqs: [...#Requirement] & {separator: ","}
}

#Requirement: {
	// 例如 T: Equatable, U == Collection
	// 简化表示
	left:  #Identifier | #Type
	op:    ":" | "=="
	right: #Type
}

// ------------------------------------------------------------
// 顶层编译单元
// ------------------------------------------------------------
#CompilationUnit: {
	kind: "file"
	stmts: [...{
		oneOf: [
			#ImportDecl,
			#TopLevelDecl,
			#Statement,
		]
	}]
}

#ImportDecl: {
	kind: "decl"
	"import": "import"
	module:   #Identifier
}

#TopLevelDecl: {
	oneOf: [
		#FunctionDeclaration,
		#VariableDeclaration,
		#ClassDecl,
		#StructDecl,
		// ...
	]
}

// ------------------------------------------------------------
// 示例：变量声明
// ------------------------------------------------------------
#VariableDeclaration: {
	kind: "decl"
	attrs?: [...#Attribute]
	mods?:  [...#Modifier]
	binding: "let" | "var"
	pattern: #Pattern
	typeAnno?: #TypeAnnotation
	init?: {
		"=":  "="
		expr: #Expression
	}
	constraints: [
		"若 binding 为 'let'，变量不可变。",
	]
}
CUE 设计的核心优势体现
1. 类型约束即文档
cue
#Parameter: {
	external?: #Identifier
	local:     #Identifier
	":":       ":"
	type:      #Type
	default?: {
		"=":  "="
		expr: #Expression
	}
}
这里明确定义了参数的结构，任何不符合此结构的数据在 CUE 评估时会直接报错。

2. 继承与组合
cue
#Identifier: #Token & {
	pattern: "^`?[a-zA-Z_][a-zA-Z0-9_]*`?$"
}
#Identifier 继承了 #Token 的所有字段并扩展了 pattern 约束。

3. 枚举与互斥
cue
binding: "let" | "var"        // 二选一
throws?: "throws" | "rethrows" // 可选但二选一
4. 重复与分隔符
cue
params: [...#Parameter] & {separator: ","}
利用 CUE 的结构体合并特性，可以为列表附加元数据（如分隔符），这在普通 JSON/YAML 中难以优雅表达。

5. 自校验与模块化
可以将 #Token、#Type 等定义在独立的 .cue 文件中，通过 import 复用。

使用 cue vet 命令即可验证整个语法描述文件是否自洽。
