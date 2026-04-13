## CUE 语法描述设计文档

### 1. 概述

本项目使用 **CUE (Configure Unify Execute)** 语言为仓颉编程语言核心特性输出一份结构化描述文件 `cangjie.cue`，用于指导 AI 快速学习掌握仓颉语言的语法与语义。

### 2. 设计思路

参考 Swift 的 CUE 语法描述示例，我们基于以下原则为仓颉语言设计了 CUE 描述：

1. **以语义为核心，而非纯语法 AST**  
   不同于 Swift 示例中精细的 AST 节点定义（`#Token`、`#CodeBlock`、递归 `#Type`），仓颉描述侧重于 **语言特性的结构化表达**，适合 AI 快速理解并生成代码。每个定义块既是类型约束，也是文档。

2. **分章节组织，覆盖全部核心特性**  
   共 20 个章节，从词法元素到项目管理，逐层递进：
   - §1 词法元素（关键字、标识符、字面量）
   - §2 类型系统（基本类型、泛型、Option、元组、函数类型）
   - §3 变量声明（let/var/const）
   - §4 函数（参数、Lambda、闭包、运算符重载、管道、组合）
   - §5 类型定义（class/struct/interface/enum）
   - §6 泛型
   - §7 控制流（if/while/for-in/match）
   - §8 模式匹配
   - §9 错误处理
   - §10 并发编程
   - §11 集合类型
   - §12 扩展
   - §13 属性
   - §14 包与模块
   - §15 宏与注解
   - §16 反射
   - §17 C FFI 互操作
   - §18 const 求值
   - §19 项目管理
   - §20 综合代码示例

3. **CUE 核心优势的运用**
   - **类型约束即文档**：每个 `#Definition` 块既定义了结构约束，也包含了 `description`、`example`、`constraint` 等说明字段
   - **枚举与互斥**：使用 CUE 的 disjunction（`"let" | "var" | "const"`）精确表达互斥选项
   - **结构继承与复用**：通过 CUE 的 `&` 合并运算实现结构组合
   - **列表与元数据**：`[...#Type]` 表达可变长列表，附加元数据如分隔符
   - **自校验**：可通过 `cue vet` 验证描述文件自洽性

4. **实用导向**  
   包含完整的 `#Examples` 块，提供 Hello World、类与接口、枚举匹配、泛型、并发等典型场景的代码示例，让 AI 能直接学习并模仿。

### 3. 与 Swift 示例的对比

| 维度 | Swift 示例 | 仓颉 cangjie.cue |
|------|-----------|------------------|
| 粒度 | 细粒度 AST 节点（Token/Expression/Statement） | 语义特性级别（FunctionDeclaration/ClassDeclaration） |
| 目标 | 精确语法校验 | AI 学习与代码生成指导 |
| 结构 | 语法产生式风格 | 特性文档 + 结构约束混合 |
| 示例 | 少量内联 | 独立示例章节 + 内联示例 |
| 约束 | 语法层面（separator/嵌套） | 语义层面（constraint 文字描述） |

### 4. 校验方法

为确保 CUE 描述的准确性，我们从 `cangjie.cue` 推导出仓颉代码并使用 Cangjie SDK 1.0.5 构建运行验证：

1. 根据 CUE 中每个章节的语法描述，编写对应的仓颉测试代码
2. 使用 `cjpm build` 编译验证语法正确性
3. 使用 `cjpm run` 运行验证语义正确性

已验证通过的特性：
- ✅ 基本数据类型（整数/浮点/布尔/字符/字符串/元组）
- ✅ 变量声明（let/var/const）
- ✅ 函数定义（位置参数、命名参数、默认值、Lambda、管道运算符）
- ✅ 类定义（继承、接口实现、构造函数、属性、类型检查与转换）
- ✅ 结构体（值类型、mut 函数）
- ✅ 枚举与模式匹配（参数化构造器、match 表达式、模式守卫）
- ✅ 泛型函数
- ✅ 控制流（if 表达式、while、for-in、Range、where 过滤、步长）
- ✅ Option 类型（?? 合并、if-let）
- ✅ 错误处理（自定义异常、try-catch-finally）
- ✅ 集合类型（Array、ArrayList、HashMap、HashSet）
- ✅ 扩展（extend + 接口实现）
- ✅ 并发编程（spawn/Future、AtomicInt64、Mutex/synchronized）
- ✅ const 求值（const 变量、const 函数）

### 5. 文件结构

```
CangjieFeatures/
├── cangjie.cue      # 仓颉语言核心特性 CUE 描述文件
├── design.md        # 本设计文档
└── README.md
```

### 6. 使用方式

AI 可将 `cangjie.cue` 作为参考文档，通过以下方式学习仓颉语言：

1. **查阅语法**：根据章节定义查找具体语法结构（如 `#FunctionDeclaration` 了解函数声明）
2. **理解约束**：阅读 `constraint` 和 `description` 字段了解语义规则
3. **参考示例**：使用 `#Examples` 章节中的完整代码作为模板
4. **类型推导**：根据 `#TypeRef`、`#Generics` 等定义理解类型系统

---

### 附录：原始 CUE 设计参考（Swift 示例）

以下是用 CUE 语言对 Swift 部分语法的完整描述设计，展示了 CUE 在类型约束、结构复用、默认值及严谨嵌套方面的优势。

```cue
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
```

CUE 设计的核心优势体现：

**1. 类型约束即文档**
```cue
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
```
这里明确定义了参数的结构，任何不符合此结构的数据在 CUE 评估时会直接报错。

**2. 继承与组合**
```cue
#Identifier: #Token & {
	pattern: "^`?[a-zA-Z_][a-zA-Z0-9_]*`?$"
}
```
`#Identifier` 继承了 `#Token` 的所有字段并扩展了 `pattern` 约束。

**3. 枚举与互斥**
```cue
binding: "let" | "var"        // 二选一
throws?: "throws" | "rethrows" // 可选但二选一
```

**4. 重复与分隔符**
```cue
params: [...#Parameter] & {separator: ","}
```
利用 CUE 的结构体合并特性，可以为列表附加元数据（如分隔符），这在普通 JSON/YAML 中难以优雅表达。

**5. 自校验与模块化**
可以将 `#Token`、`#Type` 等定义在独立的 `.cue` 文件中，通过 `import` 复用。
使用 `cue vet` 命令即可验证整个语法描述文件是否自洽。
