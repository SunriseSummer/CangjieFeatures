// ============================================================
// cangjie.cue — 仓颉编程语言核心特性 CUE 描述
// 用于指导 AI 快速学习掌握仓颉语言语法与语义
// ============================================================
package cangjie

// ============================================================
// §1  词法元素
// ============================================================

// 关键字分类
#Keywords: {
	// 声明关键字
	declaration: ["class", "struct", "enum", "interface", "func",
		"let", "var", "const", "type", "extend", "macro",
		"package", "import", "main"]

	// 修饰符关键字
	modifier: ["public", "private", "protected", "internal",
		"open", "override", "redef", "abstract", "sealed",
		"static", "mut", "unsafe"]

	// 控制流关键字
	controlFlow: ["if", "else", "while", "do", "for", "in",
		"match", "case", "break", "continue", "return",
		"try", "catch", "finally", "throw", "spawn"]

	// 类型关键字
	typeKeywords: ["where", "as", "is", "this", "super", "This",
		"true", "false", "Nothing"]

	// 运算符关键字
	operatorKeywords: ["operator", "inout"]
}

// 标识符规则
#Identifier: {
	description: """
		标识符以 Unicode XID_Start 字符或下划线开头，
		后跟 XID_Continue 字符。编译器对标识符做 NFC 规范化。
		使用反引号可将关键字转义为标识符，如 `class`。
		"""
	pattern:  "^[\\p{XID_Start}_][\\p{XID_Continue}]*$"
	examples: ["myVar", "_count", "中文名", "`class`"]
}

// 字面量
#Literals: {
	integer: {
		description: "整数字面量，支持二进制、八进制、十进制、十六进制前缀及类型后缀"
		prefixes: {
			binary:      "0b | 0B"
			octal:       "0o | 0O"
			hexadecimal: "0x | 0X"
			decimal:     "无前缀"
		}
		suffixes: ["i8", "i16", "i32", "i64", "u8", "u16", "u32", "u64"]
		separator:  "_"
		examples:   ["42", "0xFF", "0b1010", "0o77", "100_000i64"]
	}
	float: {
		description: "浮点字面量，十进制用 e/E 指数，十六进制用 p/P 指数"
		suffixes: ["f16", "f32", "f64"]
		examples: ["3.14", "1.0e10", "0x1.0p10", "2.5f32"]
	}
	boolean: {
		values: ["true", "false"]
	}
	rune: {
		description: "Unicode 字符字面量，用 r'' 包裹"
		examples:    ["r'a'", "r'\\n'", "r'\\u{4f60}'"]
	}
	string: {
		description: "字符串字面量，不可变 UTF-8 编码"
		forms: {
			singleLine:  "\"hello\""
			multiLine:   "\"\"\"多行内容\"\"\""
			raw:         "#\"不解释转义\"#"
			rawMultiLine: "#\"\"\"原始多行\"\"\"#"
		}
		interpolation: {
			syntax:      "${expr}"
			description: "在非原始字符串中嵌入表达式"
			example:     "\"name is ${name}\""
		}
	}
	byte: {
		description: "字节字面量，用 b'' 包裹，值为 UInt8"
		examples:    ["b'A'", "b'\\x41'"]
	}
	unit: {
		description: "Unit 类型唯一值 ()，表示无有意义的返回值"
		literal:     "()"
	}
}

// ============================================================
// §2  类型系统
// ============================================================

// 基本类型
#PrimitiveTypes: {
	integer: ["Int8", "Int16", "Int32", "Int64", "IntNative",
		"UInt8", "UInt16", "UInt32", "UInt64", "UIntNative"]
	float:    ["Float16", "Float32", "Float64"]
	boolean:  "Bool"
	character: "Rune"
	string:   "String"
	unit:     "Unit"
	nothing: {
		description: "Nothing 是所有类型的子类型，无任何值，是 break/continue/return/throw 的类型"
	}
}

// 类型引用
#TypeRef: {
	description: "类型引用，可为简单类型、泛型实例、Option 简写、元组类型或函数类型"
	oneOf: ["#SimpleType", "#GenericType", "#OptionType",
		"#TupleType", "#FunctionType"]
}

#SimpleType: {
	name: string
	examples: ["Int64", "String", "Bool", "MyClass"]
}

#GenericType: {
	name:     string
	typeArgs: [...#TypeRef]
	syntax:   "Name<T1, T2>"
	examples: ["Array<Int64>", "HashMap<String, Int64>", "Option<Bool>"]
}

#OptionType: {
	description: "Option<T> 的简写形式"
	syntax:      "?T"
	equivalence: "?T == Option<T>"
	constructors: ["Some(value)", "None"]
	unwrap: {
		coalescing: "expr ?? defaultValue"
		safeAccess: "expr?.member"
		forced:     "expr.getOrThrow()"
		patternMatch: "match (opt) { case Some(v) => ... case None => ... }"
		ifLet:      "if (let Some(v) <- opt) { ... }"
	}
}

#TupleType: {
	description: "元组类型，至少 2 个元素，固定长度不可变"
	syntax:      "(T1, T2, ..., TN)"
	access:      "t[index]  // index 必须是编译期整数字面量"
	constraint:  "N >= 2"
	examples: ["(Int64, String)", "(Bool, Float64, Rune)"]
}

#FunctionType: {
	description: "函数类型，参数类型列表 -> 返回类型，右结合"
	syntax:      "(P1, P2) -> R"
	examples:    ["(Int64) -> String", "() -> Unit", "(Int64, Int64) -> Bool"]
}

// 类型关系
#TypeRelations: {
	subtyping: {
		description: """
			仓颉使用名义子类型系统。
			- class Sub <: Super（单继承）
			- class/struct <: Interface（接口实现）
			- 元组类型协变
			- 函数类型：参数逆变，返回值协变
			- Nothing <: T 对所有类型 T
			- T <: Any 对所有类型 T
			"""
	}
	typeCheck: {
		syntax:      "expr is Type"
		description: "运行时类型检查，返回 Bool"
	}
	typeCast: {
		syntax:      "expr as Type"
		description: "安全类型转换，返回 Option<Type>"
	}
	numericConversion: {
		syntax:      "TargetType(expr)"
		description: "数值类型显式转换，如 Int64(someInt32)"
	}
	typeAlias: {
		syntax:      "type Alias = OriginalType"
		description: "类型别名，不创建新类型，仅顶层允许"
		generic:     "type Alias<T> = OriginalType<T>"
	}
}

// ============================================================
// §3  变量声明
// ============================================================

#VariableDeclaration: {
	immutable: {
		keyword: "let"
		syntax:  "let name: Type = expr"
		description: """
			不可变变量，声明后不可重新赋值。
			值类型：内容也不可变。
			引用类型：引用不可变，但对象内容可通过成员方法修改。
			"""
		typeInference: "let x = 42  // 推断为 Int64"
	}
	mutable: {
		keyword: "var"
		syntax:  "var name: Type = expr"
		description: """
			可变变量，可重新赋值。
			"""
	}
	constant: {
		keyword: "const"
		syntax:  "const NAME = constExpr"
		description: """
			编译期常量，必须用编译期可求值的表达式初始化。
			支持 const 表达式：字面量、const 变量、const 函数调用、算术运算等。
			"""
	}
	constraint: "变量声明必须初始化（const 在声明处，let/var 至少在首次使用前）"
}

// ============================================================
// §4  函数
// ============================================================

#FunctionDeclaration: {
	syntax: "func name(params): ReturnType { body }"
	description: """
		函数声明支持：
		- 位置参数和命名参数
		- 默认值（仅命名参数）
		- 返回值类型推断
		- 函数体最后一个表达式作为返回值
		"""
	example: """
		func add(a: Int64, b: Int64): Int64 {
		    a + b
		}
		"""

	parameters: {
		positional: {
			syntax:  "name: Type"
			description: "位置参数，调用时按顺序传递"
		}
		named: {
			syntax:  "name!: Type"
			description: "命名参数，调用时用 name: value 传递"
			example: """
				func greet(name!: String, greeting!: String = \"Hello\"): String {
				    \"${greeting}, ${name}!\"
				}
				greet(name: \"World\")
				"""
		}
		defaultValue: {
			syntax:      "name!: Type = defaultExpr"
			description: "仅命名参数支持默认值"
		}
		variadic: {
			syntax:      "func f(args: Array<T>)"
			description: "变长参数作为最后一个参数，调用时直接传多个值"
		}
		constraint: "函数参数在函数体内不可修改"
	}

	returnType: {
		explicit: "func f(): Int64 { 42 }"
		inferred: "如果函数体可推断，可省略返回类型"
		unit:     "无返回值时返回类型为 Unit，可省略"
	}
}

#Lambda: {
	syntax: "{ params => body }"
	description: """
		Lambda 表达式（匿名函数）。
		参数类型可从上下文推断。
		带类型参数: { x: Int64, y: Int64 => x + y }
		无参数: { => expr }
		单表达式自动返回。
		"""
	examples: [
		"{ x: Int64 => x * x }",
		"{ x: Int64, y: Int64 => x + y }",
		"{ => println(\"hello\") }",
		"{ s => s.size }  // 类型推断",
	]
	constraint: """
		参数语法: { x: Type, y: Type => body }
		注意：参数不用小括号包裹。
		捕获 var 变量的 lambda 不可逃逸（不可赋值给变量、不可传给 spawn 等）。
		"""
}

#Closure: {
	description: """
		闭包会捕获外层作用域的变量。
		let 变量：按值捕获，可逃逸。
		var 变量：按引用捕获，不可逃逸（不可赋值、不可传递、不可返回），只能直接调用。
		"""
}

#OperatorOverloading: {
	syntax: "operator func op(params): ReturnType { body }"
	description: """
		可在 class/struct/enum/extend/interface 中重载运算符。
		一元运算符: operator func -(): Type
		二元运算符: operator func +(rhs: Type): Type
		下标运算符: operator func [](index: Int64): Type（取值）
		下标赋值: operator func [](index: Int64, value!: Type): Unit（赋值，使用 value! 命名参数）
		函数调用: operator func ()(args): Type
		"""
	overloadable: ["!", "-（一元）", "**", "*", "/", "%", "+", "-（二元）",
		"<<", ">>", "<", "<=", ">", ">=", "==", "!=",
		"&", "^", "|", "[]", "()"]
	constraint: "重载 == 自动获得 !=；重载 < 自动获得 >, <=, >=；重载二元运算符自动获得复合赋值"
}

#TrailingLambda: {
	syntax: "func(args) { lambdaBody }"
	description: """
		当函数最后一个参数是函数类型时，
		可将 lambda 写在调用括号之外。
		若无其他参数，可省略括号。
		"""
	examples: [
		"list.forEach { item => println(item) }",
		"list.map { x => x * 2 }",
	]
}

#PipeOperator: {
	syntax: "expr |> func"
	description: """
		管道运算符，将左侧表达式作为右侧函数的第一个参数。
		等价于 func(expr)。支持链式调用。
		"""
	example: "data |> parse |> validate |> save"
}

#CompositionOperator: {
	syntax: "f ~> g"
	description: """
		函数组合运算符，创建新函数 { x => g(f(x)) }。
		f 的返回类型必须与 g 的参数类型匹配。
		"""
}

// ============================================================
// §5  类型定义
// ============================================================

#ClassDeclaration: {
	syntax: "class ClassName { members }"
	description: """
		引用类型。支持单继承和多接口实现。
		class Sub <: Super & Interface1 & Interface2 { }
		"""

	members: {
		instanceVar:  "let/var name: Type = expr"
		staticVar:    "static let/var name: Type = expr"
		constructor:  "init(params) { body }"
		primaryCtor: {
			syntax: """
				class Name {
				    Name(let field1: T1, var field2: T2) { body }
				}
				"""
			description: """
				主构造函数在类体内声明，名称与类名相同。
				参数前加 let/var 自动声明为成员变量。
				注意：主构造函数声明在类体内部，不在类名后。
				"""
		}
		destructor:   "~init() { cleanup }"
		memberFunc:   "func name(params): Type { body }"
		staticFunc:   "static func name(params): Type { body }"
		property: {
			readOnly: "prop name: Type { get() { expr } }"
			readWrite: "mut prop name: Type { get() { expr } set(v) { ... } }"
		}
	}

	inheritance: {
		syntax:   "class Sub <: Super { }"
		constraint: """
			单继承。父类方法必须标记 open 才能被子类 override。
			override: 覆盖父类 open 方法，保持签名一致。
			redef: 重定义父类 open 方法，可改变签名。
			"""
	}

	abstract: {
		syntax:   "abstract class Name { }"
		description: "抽象类不可实例化，可包含无方法体的抽象方法"
		sealed:   "sealed abstract class Name { } — 仅同包内可继承"
	}

	accessModifiers: {
		private:   "仅当前类内可访问"
		internal:  "同包及子包可访问（默认）"
		protected: "同模块及子类可访问"
		public:    "全局可访问"
	}
}

#StructDeclaration: {
	syntax: "struct StructName { members }"
	description: """
		值类型。赋值时拷贝。不支持继承，可实现接口。
		let 变量持有的 struct 的所有字段都不可修改。
		"""

	members: {
		instanceVar:  "let/var name: Type = expr"
		staticVar:    "static let/var name: Type = expr"
		constructor:  "init(params) { body }"
		primaryCtor: {
			syntax: """
				struct Name {
				    Name(let field1: T1, var field2: T2) { body }
				}
				"""
		}
		memberFunc:   "func name(params): Type { body }"
		mutFunc: {
			syntax: "mut func name(params): Type { body }"
			description: """
				mut 函数可修改 struct 实例。
				只有 var 变量持有的 struct 才能调用 mut 函数。
				"""
		}
		property: {
			readOnly:  "prop name: Type { get() { expr } }"
			readWrite: "mut prop name: Type { get() { expr } set(v) { ... } }"
		}
	}
	constraint: "struct 不允许直接或间接的递归定义"
}

#InterfaceDeclaration: {
	syntax: "interface InterfaceName { members }"
	description: """
		接口定义一组行为契约。
		可包含函数签名、默认实现、属性、静态方法。
		支持多继承: interface I <: I1 & I2 { }
		"""

	members: {
		function:      "func name(params): Type"
		defaultImpl:   "func name(params): Type { defaultBody }"
		staticFunc:    "static func name(params): Type { body }"
		property:      "prop name: Type"
		mutFunc:       "mut func name(params): Type"
	}

	implementation: {
		byClass:  "class C <: I { /* 实现接口方法 */ }"
		byStruct: "struct S <: I { /* 实现接口方法 */ }"
		byExtend: "extend ExistingType <: I { /* 实现接口方法 */ }"
	}

	sealed: {
		syntax:      "sealed interface Name { }"
		description: "仅同包内可实现"
	}

	any: {
		description: "Any 是内置顶层接口，所有类型都是 Any 的子类型"
	}

	diamondProblem: "当多个接口提供同名默认实现时，实现类必须显式 override 消歧义"
}

#EnumDeclaration: {
	syntax: """
		enum EnumName {
		    | Constructor1
		    | Constructor2(Type1, Type2)
		}
		"""
	description: """
		枚举类型，每个构造器可有参数，也可无参数。
		支持成员函数、属性、递归定义。
		"""

	features: {
		parameterized:  "| Constructor(ParamType)"
		recursive:      "枚举可引用自身类型"
		memberFunc:     "可在 enum 中定义函数和属性"
		nonExhaustive:  "使用 ... 作为兜底构造器"
	}

	example: """
		enum Color {
		    | Red | Green | Blue
		    | Custom(UInt8, UInt8, UInt8)

		    func description(): String {
		        match (this) {
		            case Red => \"red\"
		            case Green => \"green\"
		            case Blue => \"blue\"
		            case Custom(r, g, b) => \"rgb(${r},${g},${b})\"
		        }
		    }
		}
		"""
}

// ============================================================
// §6  泛型
// ============================================================

#Generics: {
	syntax: "<T>  或  <T, U>"
	description: """
		泛型可用于函数、类、结构体、枚举、接口。
		通过 where 子句添加类型约束。
		"""

	typeParameter: {
		syntax:   "<T>"
		examples: ["<T>", "<K, V>", "<T, U, R>"]
	}

	constraint: {
		syntax:   "where T <: Bound"
		multiple: "where T <: Bound1 & Bound2"
		examples: [
			"func max<T>(a: T, b: T): T where T <: Comparable { ... }",
			"class Container<T> where T <: ToString { ... }",
		]
	}

	variance: {
		description: """
			用户自定义泛型类型默认不型变。
			元组类型协变。
			函数类型参数逆变、返回值协变。
			"""
	}

	example: """
		func swap<T>(a: T, b: T): (T, T) {
		    (b, a)
		}
		"""
}

// ============================================================
// §7  控制流
// ============================================================

#IfExpression: {
	syntax: """
		if (condition) {
		    thenBranch
		} else {
		    elseBranch
		}
		"""
	description: """
		if 是表达式，有返回值。
		条件必须是 Bool 类型。
		支持 else if 链式。
		"""
	example: """
		let abs = if (x >= 0) { x } else { -x }
		"""
}

#WhileExpression: {
	syntax: """
		while (condition) {
		    body
		}
		"""
	doWhile: """
		do {
		    body
		} while (condition)
		"""
	description: "while/do-while 循环，返回类型为 Unit"
}

#ForInExpression: {
	syntax: "for (item in iterable) { body }"
	description: """
		遍历实现了 Iterable<T> 接口的集合。
		支持 where 过滤、元组解构、break/continue。
		"""

	range: {
		halfOpen: "0..10      // 0 到 9"
		closed:   "0..=10     // 0 到 10"
		step:     "0..10 : 2  // 0, 2, 4, 6, 8"
	}

	whereFilter: "for (i in 0..100 where i % 2 == 0) { ... }"

	destructuring: """
		for ((key, value) in pairs) {
		    println(\"${key}: ${value}\")
		}
		"""

	desugar: """
		// for (i in col) { body }
		// 等价于：
		var it = col.iterator()
		while (let Some(i) <- it.next()) {
		    body
		}
		"""
}

#MatchExpression: {
	syntax: """
		match (expr) {
		    case pattern1 => result1
		    case pattern2 where guard => result2
		    case _ => defaultResult
		}
		"""
	description: """
		模式匹配表达式，可用于值解构。
		支持多种模式类型，要求穷举。
		"""
}

// ============================================================
// §8  模式匹配
// ============================================================

#Patterns: {
	constant: {
		description: "匹配常量值"
		example:     "case 0 => \"zero\""
	}
	wildcard: {
		description: "通配符，匹配任意值"
		syntax:      "_"
		example:     "case _ => \"other\""
	}
	binding: {
		description: "绑定匹配值到变量"
		example:     "case x => \"got ${x}\""
	}
	tuple: {
		description: "元组解构"
		example:     "case (x, y) => x + y"
	}
	typePattern: {
		description: "类型模式匹配"
		example:     "case s: String => s.size"
	}
	enumPattern: {
		description: "枚举构造器匹配"
		example:     "case Some(v) => v"
	}
	guard: {
		description: "模式守卫"
		syntax:      "case pattern where condition => ..."
	}
	or: {
		description: "多模式用 | 连接（不可含绑定变量）"
		example:     "case 1 | 2 | 3 => \"small\""
	}
	nested: {
		description: "模式可任意嵌套"
		example:     "case (Some(x), None) => x"
	}
}

#IfLet: {
	syntax: "if (let Some(v) <- optExpr) { useV }"
	description: "条件模式匹配，当模式匹配成功时执行代码块"
}

#WhileLet: {
	syntax: "while (let Some(v) <- iterator.next()) { useV }"
	description: "循环模式匹配，直到模式不匹配时停止"
}

// ============================================================
// §9  错误处理
// ============================================================

#ErrorHandling: {
	hierarchy: {
		description: """
			Error: 系统级错误，不应主动抛出或捕获
			Exception: 可恢复的异常，应捕获处理
			"""
	}

	throw: {
		syntax:      "throw exceptionExpr"
		description: "抛出异常，表达式类型必须是 Exception 的子类"
		constraint:  "仓颉异常是非检查异常，编译器不强制处理"
	}

	tryCatch: {
		syntax: """
			try {
			    riskyCode
			} catch (e: SpecificException) {
			    handleSpecific
			} catch (e: Exception) {
			    handleGeneral
			} finally {
			    cleanup
			}
			"""
		catchPattern: {
			single:   "catch (e: ExceptionType)"
			union:    "catch (e: Type1 | Type2)"
			wildcard: "catch (_)"
		}
	}

	tryWithResources: {
		syntax: """
			try (resource = acquireResource()) {
			    useResource
			}
			"""
		description: "资源自动关闭，resource 必须实现 Resource 接口"
	}

	customException: {
		example: """
			class MyException <: Exception {
			    public init(message: String) {
			        super(message)
			    }
			}
			"""
	}

	builtinExceptions: [
		"NegativeArraySizeException",
		"IndexOutOfBoundsException",
		"NoneValueException",
		"OverflowException",
		"IllegalArgumentException",
		"IllegalStateException",
		"ConcurrentModificationException",
		"ArithmeticException",
		"UnsupportedException",
	]
}

// ============================================================
// §10  并发编程
// ============================================================

#Concurrency: {
	threadModel: "M:N 线程模型，轻量级语言线程映射到 OS 线程"

	spawn: {
		syntax:      "let future = spawn { => expr }"
		description: "创建新线程执行代码块，返回 Future<T>"
		example: """
			let f: Future<Int64> = spawn { =>
			    heavyComputation()
			}
			let result = f.get()
			"""
	}

	future: {
		methods: {
			get:       "get(): T — 阻塞等待结果"
			getTimeout: "get(timeout: Duration): T — 超时等待"
			tryGet:    "tryGet(): Option<T> — 非阻塞获取"
			cancel:    "cancel(): Unit — 取消执行"
		}
	}

	atomics: {
		types: ["AtomicInt8", "AtomicInt16", "AtomicInt32", "AtomicInt64",
			"AtomicUInt8", "AtomicUInt16", "AtomicUInt32", "AtomicUInt64",
			"AtomicBool", "AtomicReference<T>"]
		operations: ["load()", "store(val)", "swap(val)",
			"compareAndSwap(expect, desired)",
			"fetchAdd(val)", "fetchSub(val)",
			"fetchAnd(val)", "fetchOr(val)"]
		import: "import std.sync.*"
		constraint: "不使用泛型 Atomic<T>，使用具体类型如 AtomicInt64"
	}

	mutex: {
		syntax: "let mtx = Mutex()"
		methods: ["lock()", "unlock()", "tryLock()", "condition()"]
		synchronized: {
			syntax: """
				synchronized(mtx) {
				    criticalSection
				}
				"""
			description: "自动加锁和解锁"
		}
		constraint: "Mutex 替代已废弃的 ReentrantMutex"
	}

	condition: {
		methods: ["wait()", "wait(timeout: Duration): Bool",
			"waitUntil(predicate): Unit",
			"waitUntil(predicate, timeout: Duration): Bool",
			"notify()", "notifyAll()"]
		constraint: "调用 condition() 前必须先持有锁"
	}

	sleep: "sleep(duration: Duration)"
	threadLocal: "ThreadLocal<T>"
}

// ============================================================
// §11  集合类型
// ============================================================

#Collections: {
	array: {
		syntax:      "Array<T>"
		description: "固定长度数组，引用类型共享存储"
		literal:     "[1, 2, 3]"
		emptyLiteral: "Array<Int64>()"
		constructor: {
			withRepeat: "Array<Int64>(5, repeat: 0)"
			withLambda: "Array<Int64>(5) { i => i * 2 }"
		}
		access:  "arr[index]"
		slice:   "arr[start..end]"
		size:    "arr.size"
	}

	arrayList: {
		syntax:      "ArrayList<T>"
		description: "可变长动态数组"
		import:      "import std.collection.*"
		constructor: "ArrayList<Int64>()"
		methods:     ["append(elem)", "remove(index)", "size", "get(index)", "set(index, elem)"]
	}

	hashMap: {
		syntax:      "HashMap<K, V>"
		description: "哈希映射表"
		import:      "import std.collection.*"
		constructor: "HashMap<String, Int64>()"
		methods: {
			add:      "map.add(key, value)"
			subscriptGet: "map[key]  // 键不存在时抛出异常"
			subscriptSet: "map[key] = value"
			contains: "map.contains(key)"
			remove:   "map.remove(key)"
			size:     "map.size"
		}
		constraint: "使用 .add() 而非 .put()"
	}

	hashSet: {
		syntax:      "HashSet<T>"
		description: "哈希集合"
		import:      "import std.collection.*"
		constructor: "HashSet<Int64>()"
		methods:     ["add(elem)", "remove(elem)", "contains(elem)", "size"]
	}

	varray: {
		syntax:      "VArray<T, $N>"
		description: "值类型固定长度数组，编译期确定大小"
		constructor: "VArray<Int64, $3>(repeat: 0)"
		constraint:  "不能存放引用类型、枚举类型、lambda"
	}

	range: {
		halfOpen: "start..end"
		closed:   "start..=end"
		step:     "start..end : step"
		description: "区间类型，实现 Iterable 接口"
	}

	iterable: {
		description: """
			所有可迭代集合实现 Iterable<T> 接口。
			interface Iterable<T> {
			    func iterator(): Iterator<T>
			}
			Iterator<T> 的 next() 返回 Option<T>。
			"""
	}
}

// ============================================================
// §12  扩展
// ============================================================

#Extension: {
	syntax: "extend Type { members }"
	description: """
		为已有类型添加新方法和属性（不添加存储字段）。
		可以同时实现接口: extend Type <: Interface { }
		"""

	direct: {
		syntax: "extend MyClass { func newMethod(): Unit { } }"
	}
	withInterface: {
		syntax: "extend MyClass <: ToString { func toString(): String { ... } }"
	}
	multipleInterfaces: {
		syntax: "extend MyClass <: I1 & I2 { ... }"
	}
	generic: {
		syntax:   "extend<T> Container<T> where T <: Printable { ... }"
		concrete: "extend Container<Int64> { ... }"
	}

	constraints: [
		"不能添加存储型成员变量",
		"不能使用 open/override/redef",
		"不能访问 private 成员",
		"不能遮盖已有同签名成员",
		"孤儿规则：类型或接口至少有一个定义在同包内",
	]
}

// ============================================================
// §13  属性
// ============================================================

#Property: {
	readOnly: {
		syntax: """
			prop name: Type {
			    get() { expr }
			}
			"""
	}
	readWrite: {
		syntax: """
			mut prop name: Type {
			    get() { expr }
			    set(value) { ... }
			}
			"""
		description: "mut prop 可读写，仅在引用类型(class)或 struct mut 函数中可用"
	}
	description: "属性看起来像字段，但由 getter/setter 控制访问"
}

// ============================================================
// §14  包与模块
// ============================================================

#PackageSystem: {
	declaration: {
		syntax:      "package a.b.c"
		description: "包名对应 src/ 下的相对路径"
	}

	main: {
		syntax: """
			main(): Int64 {
			    0
			}
			"""
		description: "程序入口函数，返回 Int64 或 Unit"
		withArgs: "main(args: Array<String>): Int64 { ... }"
	}

	import: {
		single:    "import packagePath.item"
		wildcard:  "import packagePath.*"
		multiple:  "import { pkg1.*, pkg2.item }"
		alias:     "import longPackageName as short"
		reexport:  "public import otherPkg.item"
	}

	accessModifiers: {
		private:   "仅当前文件可见"
		internal:  "同包及子包可见（默认）"
		protected: "同模块可见"
		public:    "全局可见"
	}

	implicitImport: "core 包自动导入（包含 String, Array, println 等基础类型和函数）"
}

// ============================================================
// §15  宏与注解
// ============================================================

#Macros: {
	description: """
		仓颉支持编译期宏，在宏包 (macro package) 中定义，
		编译时对 Token 流进行变换。
		"""

	definition: {
		syntax: """
			// 在 macro package 中
			public macro MyMacro(input: Tokens): Tokens {
			    // 处理 input tokens
			    return quote( transformedCode )
			}
			"""
	}

	invocation: {
		nonAttribute: "@MacroName(codeToTransform)"
		attribute:    "@MacroName[attrArgs](codeToTransform)"
	}

	quote: {
		syntax:      "quote( code )"
		description: "将代码转为 Tokens"
		interpolation: "$(expr) 在 quote 中插入表达式结果"
	}

	astParsing: ["parseExpr(tokens)", "parseDecl(tokens)",
		"parseType(tokens)", "parsePattern(tokens)"]
}

#Annotations: {
	overflow: {
		description: "控制整数溢出行为"
		types: ["@OverflowThrowing（默认，抛出异常）",
			"@OverflowWrapping（回绕）",
			"@OverflowSaturating（饱和）"]
	}

	custom: {
		syntax: """
			@Annotation
			class MyAnnotation {
			    const init() {}
			}
			"""
		usage: "@MyAnnotation[args]"
	}
}

// ============================================================
// §16  反射
// ============================================================

#Reflection: {
	typeInfo: {
		obtain: ["TypeInfo.of(instance)", "TypeInfo.of<Type>()", "TypeInfo.get(qualifiedName)"]
		methods: [
			"getStaticVariable(name)",
			"getInstanceVariable(name)",
			"getInstanceProperty(name)",
			"getStaticFunction(name)",
			"getInstanceFunction(name)",
		]
	}
	constraint: "只能反射 public 成员"
}

// ============================================================
// §17  C FFI 互操作
// ============================================================

#CFfi: {
	foreignFunc: {
		syntax: "@C foreign func cFuncName(params): ReturnType"
		description: "声明外部 C 函数，调用需在 unsafe 块中"
	}

	unsafeBlock: {
		syntax: "unsafe { codeWithForeignCalls }"
		description: "标记不安全代码区域，允许调用 C 函数"
	}

	cFunc: {
		syntax:      "CFunc<(ParamTypes) -> ReturnType>"
		description: "C 函数指针类型"
	}

	typeMapping: {
		description: "仓颉与 C 类型对应关系"
		mapping: {
			"Int8":    "int8_t"
			"Int16":   "int16_t"
			"Int32":   "int32_t"
			"Int64":   "int64_t"
			"UInt8":   "uint8_t"
			"UInt16":  "uint16_t"
			"UInt32":  "uint32_t"
			"UInt64":  "uint64_t"
			"Float32": "float"
			"Float64": "double"
			"Bool":    "bool"
			"Unit":    "void"
		}
	}

	cPointer: {
		syntax:  "CPointer<T>"
		methods: ["read()", "write(value)", "isNull()", "toUIntNative()"]
	}

	cString: {
		description: "C 字符串类型，UTF-8 兼容"
		create:      "LibC.mallocCString(str)"
		free:        "LibC.free(cstr)"
	}

	inout: {
		syntax:      "unsafe { func(inout variable) }"
		description: "将变量地址传递为 CPointer"
	}
}

// ============================================================
// §18  const 求值
// ============================================================

#ConstEvaluation: {
	constVar: {
		syntax:      "const NAME = constExpr"
		description: "编译期常量"
	}

	constFunc: {
		syntax: """
			const func calculate(x: Int64): Int64 {
			    x * x + 1
			}
			"""
		description: """
			const 函数在编译期求值（当所有参数都是 const 时）。
			运行时参数时退化为普通函数。
			"""
	}

	constInit: {
		syntax: """
			struct Config {
			    const init(let maxSize: Int64, let name: String) {}
			}
			const cfg = Config(100, \"default\")
			"""
		description: "const 构造函数，允许创建编译期常量实例"
	}

	constExpressions: [
		"字面量（整数、浮点、布尔、字符串、Rune）",
		"const 变量引用",
		"const 函数调用",
		"算术/逻辑/比较运算",
		"枚举构造器",
		"const 数组/元组字面量",
	]
}

// ============================================================
// §19  项目管理 (cjpm)
// ============================================================

#ProjectManagement: {
	init: {
		syntax:      "cjpm init --name myProject --type=executable"
		description: "初始化项目，生成 cjpm.toml 和 src/main.cj"
	}

	build: "cjpm build"
	run:   "cjpm run"
	test:  "cjpm test"
	clean: "cjpm clean"

	config: {
		file: "cjpm.toml"
		sections: ["[package]", "[dependencies]", "[build]", "[test]", "[profile]"]
	}

	projectStructure: """
		myProject/
		├── cjpm.toml
		├── src/
		│   └── main.cj
		└── build/
		"""
}

// ============================================================
// §20  综合代码示例
// ============================================================

#Examples: {
	helloWorld: """
		main(): Int64 {
		    println(\"Hello, 仓颉!\")
		    0
		}
		"""

	classWithInterface: """
		interface Greetable {
		    func greet(): String
		}

		class Person <: Greetable {
		    private let name: String

		    public init(name: String) {
		        this.name = name
		    }

		    public func greet(): String {
		        \"Hello, I'm ${name}\"
		    }
		}
		"""

	enumWithMatch: """
		enum Shape {
		    | Circle(Float64)
		    | Rectangle(Float64, Float64)
		    | Triangle(Float64, Float64, Float64)
		}

		func area(s: Shape): Float64 {
		    match (s) {
		        case Circle(r) => 3.14159 * r * r
		        case Rectangle(w, h) => w * h
		        case Triangle(a, b, c) =>
		            let s = (a + b + c) / 2.0
		            (s * (s - a) * (s - b) * (s - c))
		    }
		}
		"""

	genericFunction: """
		func firstOrNone<T>(arr: Array<T>): Option<T> {
		    if (arr.size > 0) {
		        Some(arr[0])
		    } else {
		        None
		    }
		}
		"""

	concurrentExample: """
		import std.sync.*
		import std.time.*

		main(): Int64 {
		    let counter = AtomicInt64(0)
		    let futures = Array<Future<Unit>>(5) { _ =>
		        spawn { =>
		            for (_ in 0..1000) {
		                counter.fetchAdd(1)
		            }
		        }
		    }
		    for (f in futures) {
		        f.get()
		    }
		    println(\"Counter: ${counter.load()}\")
		    0
		}
		"""
}
