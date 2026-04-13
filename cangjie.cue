// ============================================================
// cangjie.cue — 仓颉编程语言核心语法特性 CUE 描述
// 用于指导 AI 快速学习掌握仓颉语言
// ============================================================
package cangjie

// ============================================================
// 1. 词法基础
// ============================================================

// 标识符规则
#Identifier: {
	kind: "token"
	pattern: "^[\\p{XID_Start}_][\\p{XID_Continue}]*$"
	description: """
		普通标识符以 Unicode 字母或下划线开头，后跟字母/数字/下划线。
		使用反引号可将关键字用作标识符，如 `while`、`if`。
		标识符在 Unicode NFC 等价下视为相同。
		"""
	examples: ["myVar", "_count", "`class`"]
}

// 关键字分类
#Keywords: {
	typeKeywords: ["Bool", "Int8", "Int16", "Int32", "Int64",
		"UInt8", "UInt16", "UInt32", "UInt64",
		"IntNative", "UIntNative",
		"Float16", "Float32", "Float64",
		"Rune", "String", "Array", "VArray",
		"Nothing", "Unit"]
	controlKeywords: ["break", "case", "catch", "continue", "do",
		"else", "finally", "for", "if", "in", "match",
		"return", "spawn", "synchronized", "try", "throw", "while"]
	declarationKeywords: ["abstract", "class", "const", "enum", "extend",
		"foreign", "func", "import", "init", "interface",
		"let", "macro", "main", "mut", "open", "operator",
		"override", "package", "private", "prop", "protected",
		"public", "redef", "sealed", "static", "struct",
		"super", "this", "This", "type", "unsafe", "var", "where"]
	literalKeywords: ["true", "false"]
}

// ============================================================
// 2. 基础数据类型
// ============================================================

#IntegerType: {
	kind:  "type"
	name:  "Int8" | "Int16" | "Int32" | "Int64" | "UInt8" | "UInt16" | "UInt32" | "UInt64" | "IntNative" | "UIntNative"
	literals: {
		decimal:     "42, 100i8, 255u8"
		hexadecimal: "0xFF, 0x10i16"
		octal:       "0o77, 0o10u32"
		binary:      "0b1010, 0b11i32"
		separator:   "1_000_000  // 下划线分隔"
	}
	operators: ["+", "-", "*", "/", "%", "**",
		"!", "<<", ">>", "&", "^", "|",
		"++", "--"]
	constraints: [
		"/ 为截断除法",
		"++ 和 -- 仅后缀，返回类型 Unit",
		"默认溢出行为为编译/运行时错误",
	]
}

#FloatType: {
	kind: "type"
	name: "Float16" | "Float32" | "Float64"
	literals: {
		decimal: "3.14, 2e3, 3.14f32"
		hex:     "0x1.1p0f64"
	}
	operators: ["+", "-", "*", "/", "%", "**"]
}

#BoolType: {
	kind:     "type"
	name:     "Bool"
	literals: "true | false"
	operators: ["!", "&&", "||"]
	constraint: "&& 和 || 短路求值"
}

#RuneType: {
	kind: "type"
	name: "Rune"
	literals: {
		char:    "r'a'"
		unicode: "r'\\u{4F60}'"
		escape:  "r'\\n', r'\\t', r'\\\\'"
	}
	conversion: "UInt32(rune)  Rune(uint32Value)"
}

#StringType: {
	kind: "type"
	name: "String"
	literals: {
		regular:  "\"hello\""
		multiline: "\"\"\"多行\\n字符串\"\"\""
		raw:       "#\"不转义 \\n\"#"
	}
	interpolation: {
		syntax:  "${expression}"
		example: "\"Hello, ${name}!\""
	}
	keyMethods: [".size", ".isEmpty()", ".substring(start, end)",
		".contains(str)", ".startsWith(str)", ".endsWith(str)",
		".split(delim)", ".replace(old, new)", ".trim()",
		".toUpper()", ".toLower()",
		".runes()", ".toRuneArray()", ".toUtf8()"]
	iteration: "for (byte in str) 按 UInt8 迭代；用 str.runes() 按 Rune 迭代"
}

#UnitType: {
	kind:        "type"
	name:        "Unit"
	literal:     "()"
	description: "空值类型，类似 void。无返回值的函数返回 Unit。"
}

#NothingType: {
	kind: "type"
	name: "Nothing"
	description: """
		底类型，是所有类型的子类型。
		return、break、continue、throw 表达式的类型为 Nothing。
		"""
}

#TupleType: {
	kind: "type"
	name: "Tuple"
	syntax: {
		type:    "(T1, T2, ...)"
		named:   "(name1: T1, name2: T2)"
		literal: "(1, \"hello\")"
	}
	access: {
		positional: "tuple[0], tuple[1]"
		named:      "tuple.name1"
	}
	destructuring: {
		letBinding: "let (a, b) = tuple"
		assignment: "(a, b) = (b, a)  // 交换"
		wildcard:   "(a, _) = (1, 2)  // 忽略"
	}
	constraint: "元组是不可变的值类型，支持协变子类型"
}

#ArrayType: {
	kind: "type"
	name: "Array<T>"
	syntax: {
		literal:    "[1, 2, 3]"
		empty:      "Array<Int64>()"
		sized:      "Array<Int64>(5, repeat: 0)"
		fromValues: "[value1, value2, value3]"
	}
	access: {
		read:  "arr[index]"
		write: "arr[index] = value  // 需要 var 声明"
	}
	slicing: "arr[0..5], arr[..3], arr[2..]"
	properties: [".size"]
	constraint: "定长，struct 类型但内部引用共享（赋值不深拷贝）"
}

#VArrayType: {
	kind: "type"
	name: "VArray<T, $N>"
	syntax: {
		declare: "var a: VArray<Int64, $3> = [1, 2, 3]"
		repeat:  "VArray<Int64, $5>(repeat: 0)"
	}
	constraint: "纯值类型，无 GC 开销。元素类型受限（不能包含引用类型、枚举、Lambda）"
}

#RangeType: {
	kind: "type"
	name: "Range<T>"
	syntax: {
		halfOpen: "0..5       // [0, 5)"
		closed:   "0..=5      // [0, 5]"
		stepped:  "0..10 : 2  // 步长"
		reverse:  "5..0 : -1  // 递减"
	}
}

#OptionType: {
	kind: "type"
	name: "Option<T>"
	syntax: {
		shorthand:   "?T  // 等价于 Option<T>"
		some:        "Some(value)"
		none:        "None"
		autoWrap:    "let x: ?Int64 = 42  // 自动包装为 Some(42)"
	}
	unwrapping: {
		match:      "match (opt) { case Some(v) => v; case None => default }"
		coalescing: "opt ?? defaultValue"
		safeAccess: "opt?.member"
		force:      "opt.getOrThrow()"
	}
}

// ============================================================
// 3. 变量声明
// ============================================================

#VariableDeclaration: {
	kind: "decl"
	syntax: {
		immutable:    "let name: Type = value"
		mutable:      "var name: Type = value"
		compileConst: "const name = value"
		typeInferred: "let x = 42  // 推断为 Int64"
	}
	rules: [
		"let 声明的变量不可修改",
		"var 声明的变量可修改",
		"const 编译期常量，深度不可变",
		"类型标注可省略（若可推断）",
		"全局/静态变量必须初始化",
		"局部变量可延迟初始化，但使用前必须赋值",
	]
	multiAssignment: {
		syntax:  "(a, b) = (expr1, expr2)"
		swap:    "(a, b) = (b, a)"
		partial: "(a, _) = (1, 2)"
	}
	examples: [
		"let x: Int64 = 10",
		"var y = 20",
		"const PI = 3.14159",
	]
}

// ============================================================
// 4. 函数
// ============================================================

#FunctionDeclaration: {
	kind: "decl"
	syntax: {
		basic:       "func name(params): ReturnType { body }"
		noReturn:    "func greet(name: String) { println(\"Hello, ${name}\") }"
		expression:  "func add(a: Int64, b: Int64): Int64 { a + b }"
	}
	parameters: {
		positional: "func f(a: Int64, b: String) { ... }"
		named: {
			syntax:  "func f(value: Int64, indent!: Int64 = 2): String { ... }"
			call:    "f(42, indent: 4)"
			rule:    "命名参数用 ! 标记，调用时用 参数名: 值"
		}
		defaultValue: {
			syntax: "func f(x: Int64, y!: Int64 = 0): Int64 { ... }"
			rule:   "仅命名参数支持默认值"
		}
		variadic: {
			syntax: "func sum(args: Array<Int64>): Int64 { ... }"
			call:   "sum(1, 2, 3)  // 末位 Array 参数展开"
		}
	}
	returnType: {
		explicit: "func f(): Int64 { 42 }"
		inferred: "func f() { println(\"hi\") }  // 返回 Unit"
		rule:     "函数体最后一个表达式为返回值（可省略 return）"
	}
	overloading: {
		rule: "同作用域同名函数，参数数量或类型不同即可重载"
		restriction: "静态方法和实例方法不能同名（即使参数不同）"
	}
	examples: [
		"func add(a: Int64, b: Int64): Int64 { a + b }",
		"func formatNumber(value: Int64, indent!: Int64 = 2): String { \" \" * indent + value.toString() }",
	]
}

#LambdaExpression: {
	kind: "expr"
	syntax: {
		basic:     "{ params => body }"
		noParams:  "{ => expression }"
		typed:     "{ x: Int64, y: Int64 => x + y }"
		multiLine: "{ x: Int64 =>\n    let y = x * 2\n    y + 1\n}"
	}
	rules: [
		"参数不加括号：{ x: Int64, y: Int64 => ... } 而非 { (x: Int64) => ... }",
		"捕获外部 var 变量的闭包不能逃逸（不能赋值给变量、不能作为返回值、不能传递给 spawn）",
		"捕获 var 的闭包必须直接调用：{ => count += 1 }()",
	]
	functionType: {
		syntax: "(ParamTypes) -> ReturnType"
		examples: [
			"var f: (Int64, Int64) -> Int64 = { a: Int64, b: Int64 => a + b }",
			"var g: () -> Unit = { => println(\"hi\") }",
		]
	}
	syntaxSugar: {
		trailingLambda: "myFunc(arg1) { x => x * 2 }  // 最后一个函数类型参数可提取到括号外"
		pipeline:       "5 |> square |> double  // 管道操作符"
		composition:    "f ~> g  // 函数组合，等价于 { x => g(f(x)) }"
	}
}

// ============================================================
// 5. 控制流
// ============================================================

#IfExpression: {
	kind: "expr"
	syntax: {
		basic:   "if (condition) { thenBranch }"
		ifElse:  "if (condition) { ... } else { ... }"
		chain:   "if (c1) { ... } else if (c2) { ... } else { ... }"
		asValue: "let x = if (cond) expr1 else expr2"
	}
	patternBinding: {
		syntax:  "if (let Some(x) <- optionalExpr) { ... }"
		rule:    "使用 let 模式 <- 表达式 进行条件解构"
	}
}

#WhileLoop: {
	kind:   "stmt"
	syntax: {
		while_:  "while (condition) { body }"
		doWhile: "do { body } while (condition)"
	}
}

#ForInLoop: {
	kind: "stmt"
	syntax: {
		basic:       "for (item in collection) { body }"
		range:       "for (i in 0..10) { body }"
		destructure: "for ((key, value) in map) { body }"
		filtered:    "for (x in list where x > 0) { body }"
		wildcard:    "for (_ in 0..5) { body }"
	}
	desugar: """
		for (item in coll) { ... }
		等价于:
		var it = coll.iterator()
		while (let Some(item) <- it.next()) { ... }
		"""
}

#MatchExpression: {
	kind: "expr"
	syntax: {
		basic: """
			match (expr) {
			    case pattern1 => result1
			    case pattern2 => result2
			    case _ => defaultResult
			}
			"""
	}
	patterns: {
		constant:    "case 0 => ..., case \"hello\" => ..."
		union:       "case 1 | 2 | 3 => ..."
		range:       "case 0..10 => ..."
		binding:     "case Some(x) => ...  // x 绑定解构值"
		tuple:       "case (0, y) => ..."
		typeCheck:   "case _: String => ..."
		wildcard:    "case _ => ..."
		guard:       "case Some(v) where v > 0 => ..."
		enumVariant: "case Color.Red => ..."
	}
	rules: [
		"match 是表达式，可赋值",
		"所有 case 分支返回类型必须兼容",
		"编译器检查穷尽性（使用 _ 兜底）",
	]
}

// ============================================================
// 6. 类型系统
// ============================================================

#TypeSystem: {
	kind: "system"
	hierarchy: {
		top:    "Any — 所有类型的超类型接口"
		object: "Object — 所有 class 的隐式基类"
		bottom: "Nothing — 所有类型的子类型"
	}
	subtypeRelations: {
		classInheritance:  "class Sub <: Super"
		interfaceImpl:     "class C <: Interface"
		tupleCovariant:    "(C2, C4) <: (C1, C3) 若 C2 <: C1 且 C4 <: C3"
		functionVariance:  "(U1) -> S2 <: (U2) -> S1 若 U2 <: U1（逆变）且 S2 <: S1（协变）"
		nothingSubtype:    "Nothing <: T（任意 T）"
		anySuper:          "T <: Any（任意 T）"
	}
	typeOperators: {
		is_: "expr is Type  // 运行时类型检查，返回 Bool"
		as_: "expr as Type  // 安全向下转型，返回 Option<Type>"
	}
	typeAlias: {
		syntax:  "type Alias = OriginalType"
		example: "type StringArray = Array<String>"
	}
}

// ============================================================
// 7. 类 (class)
// ============================================================

#ClassDeclaration: {
	kind: "decl"
	syntax: {
		basic: """
			class ClassName {
			    let field1: Type1
			    var field2: Type2
			
			    init(param1: Type1, param2: Type2) {
			        this.field1 = param1
			        this.field2 = param2
			    }
			
			    func method(): RetType { ... }
			}
			"""
		open_: "open class Base { ... }  // 允许被继承"
		primaryConstructor: """
			class ClassName {
			    ClassName(let field1: Type1, var field2: Type2) {}
			}
			"""
		abstract_: "abstract class Shape { abstract func area(): Float64 }"
		sealed_:   "sealed abstract class Result {}  // 仅包内继承"
	}
	members: {
		instanceField:  "let/var name: Type"
		staticField:    "static let/var name: Type"
		instanceMethod: "func name(params): RetType { body }"
		staticMethod:   "static func name(params): RetType { body }"
		abstractMethod: "abstract func name(): RetType  // 无函数体，隐式 open"
		property: {
			readOnly: "prop name: Type { get() { ... } }"
			mutable:  "mut prop name: Type { get() { ... } set(v) { ... } }"
		}
	}
	inheritance: {
		syntax:       "class Sub <: Super { ... }  // Super 须为 open 或 abstract class"
		superCall:    "super(args)  // 在 init 中调用父类构造"
		override_:    "override func method(): RetType { ... }"
		openRequired: "父类方法须标记 open 才能被 override"
	}
	accessModifiers: {
		private_:   "private    — 仅当前类型内可见"
		internal_:  "internal   — 当前包及子包可见（默认）"
		protected_: "protected  — 当前模块 + 子类可见"
		public_:    "public     — 全局可见"
	}
	thisType: "This 类型：指代当前类型，用于方法链的正确子类返回"
	finalizer: "~init() { ... }  // GC 调用，时机不确定"
	rules: [
		"主构造函数写在类体内部：ClassName(let x: T) {} 而非类名后面",
		"class 默认继承 Object",
		"class 是引用类型",
		"class 默认不可继承，需标记 open 才能被子类继承",
		"abstract class 隐式 open",
	]
}

// ============================================================
// 8. 结构体 (struct)
// ============================================================

#StructDeclaration: {
	kind: "decl"
	syntax: {
		basic: """
			struct StructName {
			    let field1: Type1
			    var field2: Type2
			
			    init(param1: Type1, param2: Type2) {
			        this.field1 = param1
			        this.field2 = param2
			    }
			}
			"""
		primaryConstructor: """
			struct Point {
			    Point(let x: Float64, let y: Float64) {}
			}
			"""
	}
	mutMethod: {
		syntax: "public mut func methodName() { field = newValue }"
		rule:   "修改 struct 自身字段的方法须标记 mut，且调用方变量须为 var"
	}
	rules: [
		"struct 是值类型，赋值即拷贝",
		"不支持继承（但可实现接口）",
		"不支持递归定义（直接或间接）",
		"仅有 var 字段 + 默认值的 struct 自动生成无参 init()，不生成带参构造",
		"需要带参构造必须手动定义 init(...) 或主构造函数",
	]
}

// ============================================================
// 9. 接口 (interface)
// ============================================================

#InterfaceDeclaration: {
	kind: "decl"
	syntax: {
		basic: """
			interface InterfaceName {
			    func method(): RetType
			    prop property: Type
			}
			"""
		defaultImpl: """
			interface Printable {
			    func toString(): String { "default" }
			}
			"""
		inheritance: "interface Shape <: Drawable { ... }"
	}
	implementation: {
		class_:    "class Circle <: Drawable { public func draw() { ... } }"
		struct_:   "struct Point <: Printable { public func toString(): String { ... } }"
		multiple:  "class C <: InterfaceA & InterfaceB { ... }"
	}
	rules: [
		"接口可以有默认方法实现",
		"接口可以有静态方法（含默认实现）",
		"接口可以有 prop 声明",
		"Any 是所有接口的隐式基接口",
		"菱形继承须在实现类中显式覆盖冲突方法",
	]
}

// ============================================================
// 10. 枚举 (enum)
// ============================================================

#EnumDeclaration: {
	kind: "decl"
	syntax: {
		basic: """
			enum EnumName {
			    | Variant1
			    | Variant2
			    | Variant3(ParamType)
			}
			"""
		recursive: """
			enum Expr {
			    | Num(Int64)
			    | Add(Expr, Expr)
			    | Mul(Expr, Expr)
			}
			"""
		withMembers: """
			enum Color {
			    | Red | Green | Blue
			    func description(): String {
			        match (this) {
			            case Red => "红"
			            case Green => "绿"
			            case Blue => "蓝"
			        }
			    }
			}
			"""
	}
	usage: {
		create: "let c = Color.Red"
		match_: "match (c) { case Red => ...; case Green => ... }"
		withPayload: "let e = Expr.Num(42)"
	}
	rules: [
		"枚举默认不支持 ==，需手动实现 operator func ==",
		"枚举可包含方法、属性、操作符重载",
		"枚举变体可携带关联值",
		"支持递归枚举定义",
	]
}

// ============================================================
// 11. 泛型
// ============================================================

#Generics: {
	kind: "feature"
	syntax: {
		function_:  "func identity<T>(a: T): T { a }"
		class_:     "class Box<T> { let value: T }"
		struct_:    "struct Pair<A, B> { let first: A; let second: B }"
		interface_: "interface Container<T> { func get(): T }"
		enum_:      "enum Option<T> { | Some(T) | None }"
	}
	constraints: {
		where_: "func max<T>(a: T, b: T): T where T <: Comparable<T> { ... }"
		multi:  "class Map<K, V> where K <: Hashable & Equatable<K> { ... }"
	}
	rules: [
		"用户定义的泛型类型是不变的：Box<Sub> 不是 Box<Super> 的子类型",
		"泛型的静态成员不能引用类型参数",
	]
}

// ============================================================
// 12. 集合类型
// ============================================================

#Collections: {
	kind: "feature"
	builtIn: {
		array: {
			type:      "Array<T>"
			create:    "[1, 2, 3] 或 Array<Int64>(5, repeat: 0)"
			fixedSize: true
		}
		varray: {
			type:   "VArray<T, $N>"
			create: "VArray<Int64, $3>(repeat: 0)"
			value:  "纯值类型，无 GC 开销"
		}
	}
	stdCollection: {
		import_:   "import std.collection.*"
		arrayList: {
			type:    "ArrayList<T>"
			create:  "ArrayList<Int64>()"
			methods: [".add(item)", ".size", ".get(index)", ".remove(index)"]
		}
		hashMap: {
			type:    "HashMap<K, V>"
			create:  "HashMap<String, Int64>()"
			methods: [".add(key, value)", ".contains(key)", ".remove(key)"]
			access:  "map[key] = value  读: map[key]（键不存在时运行时异常）"
		}
		hashSet: {
			type: "HashSet<T>"
			create: "HashSet<Int64>()"
		}
	}
}

// ============================================================
// 13. 错误处理
// ============================================================

#ErrorHandling: {
	kind: "feature"
	exceptionModel: "非检查型异常（unchecked）— 编译器不强制 catch"
	syntax: {
		throw_: "throw ExceptionType(\"message\")"
		tryCatch: """
			try {
			    riskyOperation()
			} catch (e: SpecificException) {
			    handleSpecific(e)
			} catch (e: Exception) {
			    handleGeneral(e)
			} finally {
			    cleanup()
			}
			"""
		tryWithResource: """
			try (resource = Resource()) {
			    resource.use()
			}  // 自动关闭，类须实现 Resource 接口
			"""
		multiCatch: "catch (e: TypeA | TypeB) { ... }"
	}
	customException: """
		class MyException <: Exception {
		    init(message: String) { super(message) }
		}
		"""
	builtInExceptions: [
		"Exception", "NegativeArraySizeException",
		"IllegalArgumentException", "ArithmeticException",
	]
	rules: [
		"异常不需要在函数签名中声明",
		"未捕获的异常编译通过，运行时崩溃",
	]
}

// ============================================================
// 14. 并发
// ============================================================

#Concurrency: {
	kind: "feature"
	threadModel: "M:N 用户线程映射到 OS 线程"
	spawn: {
		syntax:  "spawn { => body }"
		example: "spawn { => println(\"在新线程中执行\") }"
		rule:    "闭包不能捕获局部 var 变量（需用全局变量或原子类型）"
	}
	synchronization: {
		atomic: {
			types:  ["AtomicInt64", "AtomicBool", "AtomicReference<T>"]
			import_: "import std.sync.*"
			operations: ["load()", "store(value)", "swap(value)",
				"compareAndSwap(expected, desired)",
				"fetchAdd(delta)", "fetchSub(delta)"]
			note: "不存在泛型 Atomic<T>，必须使用具体类型如 AtomicInt64"
		}
		mutex: {
			type:   "Mutex"
			usage: """
				let m = Mutex()
				m.lock()
				try { /* 临界区 */ } finally { m.unlock() }
				"""
			note: "ReentrantMutex 已废弃，使用 Mutex"
		}
		condition: {
			create:  "let cond = mutex.condition()  // 需先持有锁"
			methods: ["wait()", "wait(timeout: Duration)", "notify()", "notifyAll()"]
			note:    "wait(timeout) 返回 Bool，timeout <= Duration.Zero 抛异常"
		}
		synchronized_: {
			syntax: "synchronized (obj) { /* 持有 obj 的监视器锁 */ }"
		}
	}
}

// ============================================================
// 15. 操作符重载
// ============================================================

#OperatorOverloading: {
	kind: "feature"
	syntax: {
		binary:    "public operator func +(right: Type): RetType { ... }"
		unary:     "public operator func -(): Type { ... }  // 无参数"
		subscriptGet: "public operator func [](index: Int64): T { ... }"
		subscriptSet: "public mut operator func [](index: Int64, value!: T): Unit { ... }"
		callOperator: "public operator func ()(args): RetType { ... }"
	}
	overloadable: ["+", "-", "*", "/", "%", "**",
		"!", "<<", ">>", "&", "^", "|",
		"==", "!=", "<", "<=", ">", ">=",
		"[]", "()"]
	rules: [
		"下标 set 使用命名参数 value!: T 而非 []= 语法",
		"struct 中的下标 set 须标记 mut：mut operator func [](index, value!: T)",
		"一元操作符不带参数",
		"二元操作符带一个参数（右操作数）",
	]
}

// ============================================================
// 16. 模式匹配
// ============================================================

#PatternMatching: {
	kind: "feature"
	ifLet: {
		syntax:  "if (let Some(x) <- optionalExpr) { ... }"
		example: "if (let Some(v) <- getValue()) { println(v) }"
	}
	whileLet: {
		syntax:  "while (let Some(item) <- iter.next()) { process(item) }"
	}
	matchExpr: {
		syntax: """
			match (expr) {
			    case Pattern => result
			    case _ => default
			}
			"""
	}
	patternTypes: [
		"常量模式: case 42, case \"hello\"",
		"通配符: case _",
		"绑定模式: case Some(x)",
		"元组模式: case (a, b)",
		"类型模式: case _: SpecificType",
		"或模式: case A | B",
		"范围模式: case 0..10",
		"守卫: case x where x > 0",
	]
}

// ============================================================
// 17. 包和导入
// ============================================================

#PackageSystem: {
	kind: "feature"
	packageDecl: {
		syntax:  "package pkg.sub"
		rule:    "与目录结构对应，相对于 src/"
		default: "不声明则为 default 包"
	}
	import_: {
		all:       "import std.collection.*"
		selective: "import std.collection.{ArrayList, HashMap}"
		single:    "import package.item"
		reexport:  "public import package.item"
	}
	projectStructure: {
		cjpmToml: """
			[package]
			name = \"myproject\"
			cjc-version = \"1.0.5\"
			output-type = \"executable\"
			
			[dependencies]
			"""
		srcDir: "src/main.cj 为入口文件"
	}
}

// ============================================================
// 18. 扩展 (extend)
// ============================================================

#Extension: {
	kind: "decl"
	syntax: {
		direct: """
			extend String {
			    public func printSize() {
			        println(\"Size: ${this.size}\")
			    }
			}
			"""
		withInterface: """
			extend<T> Array<T> <: Drawable {
			    public func draw() { println(\"Array of ${this.size}\") }
			}
			"""
		generic: """
			extend<T> Box<T> {
			    public func info() { println(\"Box\") }
			}
			"""
		constrained: """
			extend<T> Array<T> where T <: ToString {
			    public func printAll() { for (item in this) { println(item) } }
			}
			"""
	}
	rules: [
		"不能添加成员变量",
		"不能使用 open、override、redef",
		"不能访问 private 成员",
	]
}

// ============================================================
// 19. 宏与注解
// ============================================================

#MacrosAndAnnotations: {
	kind: "feature"
	macros: {
		definition: "macro MacroName(input: Tokens): Tokens { ... }"
		attrMacro:  "macro AttrMacro(attrs: Tokens, input: Tokens): Tokens { ... }"
		call:       "@MacroName 或 @MacroName(...)"
		quote:      "quote { let x = $(interpolatedValue) }"
		import_:    "import std.ast.*"
	}
	builtInAnnotations: {
		overflow: ["@OverflowThrowing", "@OverflowWrapping", "@OverflowSaturating"]
		custom: """
			@Annotation
			class Version {
			    let code: String
			    const init(code: String) { this.code = code }
			}
			@Version[\"1.0\"]
			class MyClass {}
			"""
	}
	reflection: {
		import_: "import std.reflect.TypeInfo"
		usage:   "let info = TypeInfo.of(obj)"
	}
}

// ============================================================
// 20. 常量表达式
// ============================================================

#ConstExpressions: {
	kind: "feature"
	syntax: {
		constVar:  "const PI = 3.14159"
		constFunc: "const func square(x: Int64): Int64 { x * x }"
		constInit: """
			struct Point {
			    const Point(let x: Float64, let y: Float64) {}
			}
			"""
	}
	rules: [
		"const 上下文编译期求值，非 const 上下文运行时求值",
		"const 函数内仅能访问 const 外部变量",
		"const 函数内只能声明 let/const 局部变量，不能用 var",
	]
}

// ============================================================
// 21. 入口函数
// ============================================================

#MainFunction: {
	kind: "decl"
	syntax: {
		basic:    "main(): Int64 { 0 }"
		withArgs: "main(args: Array<String>): Int64 { 0 }"
		unitReturn: "main() { println(\"Hello\") }"
	}
	rules: [
		"每个根包最多一个 main 函数",
		"不加访问修饰符",
		"可无参数或带 Array<String> 参数",
		"返回 Int64 或 Unit",
	]
}

// ============================================================
// 22. 类型转换
// ============================================================

#TypeConversion: {
	kind: "feature"
	numeric: {
		syntax:  "TargetType(value)"
		example: "Int64(3.14)  Float64(42)  Rune(65)"
	}
	stringParse: {
		import_: "import std.convert.*"
		example: "Int64.parse(\"42\")"
	}
	safeCast: {
		syntax:  "expr as TargetType  // 返回 Option<TargetType>"
		example: "let s = obj as String"
	}
	typeCheck: {
		syntax:  "expr is TargetType  // 返回 Bool"
		example: "if (obj is String) { ... }"
	}
}

// ============================================================
// 23. 属性 (prop)
// ============================================================

#Property: {
	kind: "decl"
	syntax: {
		readOnly: "prop name: Type { get() { expression } }"
		mutable: """
			mut prop name: Type {
			    get() { backingField }
			    set(v) { backingField = v }
			}
			"""
	}
	rules: [
		"prop 只读属性只有 get",
		"mut prop 可读写属性有 get 和 set",
		"属性不是字段，是计算属性",
	]
}

// ============================================================
// 24. 综合示例
// ============================================================

#ComprehensiveExample: {
	description: "展示多种核心特性的综合代码"
	code: """
		// 包声明与导入
		import std.collection.*
		
		// 接口定义
		interface Describable {
		    func describe(): String
		}
		
		// 枚举
		enum Shape {
		    | Circle(Float64)
		    | Rectangle(Float64, Float64)
		}
		
		// 类（需 open 才能被继承）
		open class Animal <: Describable {
		    let name: String
		    var age: Int64
		
		    init(name: String, age: Int64) {
		        this.name = name
		        this.age = age
		    }
		
		    public func describe(): String {
		        "${name}, age ${age}"
		    }
		
		    public open func speak(): String {
		        "..."
		    }
		}
		
		// 继承
		class Dog <: Animal {
		    init(name: String, age: Int64) {
		        super(name, age)
		    }
		
		    public override func speak(): String {
		        "Woof!"
		    }
		}
		
		// 泛型函数
		func printAll<T>(items: Array<T>) where T <: Describable {
		    for (item in items) {
		        println(item.describe())
		    }
		}
		
		// 入口
		main(): Int64 {
		    let dog = Dog("Buddy", 3)
		    println(dog.describe())
		    println(dog.speak())
		
		    // 集合
		    let map = HashMap<String, Int64>()
		    map["a"] = 1
		    map["b"] = 2
		    println(map["a"])
		
		    // 模式匹配
		    let shape = Shape.Circle(3.14)
		    let area = match (shape) {
		        case Circle(r) => 3.14159 * r * r
		        case Rectangle(w, h) => w * h
		    }
		    println("Area: ${area}")
		
		    // Option
		    let opt: ?Int64 = Some(42)
		    let val1 = opt ?? 0
		    println("Value: ${val1}")
		
		    0
		}
		"""
}
