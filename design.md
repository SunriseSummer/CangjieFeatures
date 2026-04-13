# CUE 语法描述设计文档

## 概述

本项目使用 CUE 语言对**仓颉编程语言**核心语法进行结构化描述，生成 `cangjie.cue` 文件，用于指导 AI 快速学习掌握仓颉语言。

CUE（Configure, Unify, Execute）在类型约束、结构复用、默认值及严谨嵌套方面具有显著优势，非常适合用作编程语言语法的形式化描述载体。

## 设计原则

### 1. 类型约束即文档

每个语法特性通过 CUE 定义（`#Definition`）进行结构化描述，明确定义了各字段的类型、取值范围和约束条件。

```cue
#VariableDeclaration: {
    kind: "decl"
    syntax: {
        immutable:    "let name: Type = value"
        mutable:      "var name: Type = value"
        compileConst: "const name = value"
    }
    rules: [
        "let 声明的变量不可修改",
        "var 声明的变量可修改",
        "const 编译期常量，深度不可变",
    ]
}
```

### 2. 分类组织

按语言特性分为 31 个模块：

| 编号 | 模块 | CUE 定义 |
|------|------|---------|
| 1 | 词法基础 | `#Identifier`, `#Keywords` |
| 2 | 表达式语义 | `#ExpressionSemantics` |
| 3 | 值类型与引用类型 | `#ValueReferenceTypes` |
| 4 | 基础数据类型 | `#IntegerType`, `#FloatType`, `#BoolType`, `#RuneType`, `#StringType`, `#UnitType`, `#NothingType`, `#TupleType`, `#ArrayType`, `#VArrayType`, `#RangeType`, `#OptionType` |
| 5 | 变量声明 | `#VariableDeclaration` |
| 6 | 函数 | `#FunctionDeclaration`, `#LambdaExpression` |
| 7 | 控制流 | `#IfExpression`, `#WhileLoop`, `#ForInLoop`, `#MatchExpression` |
| 8 | 类型系统 | `#TypeSystem` |
| 9 | 类 | `#ClassDeclaration` |
| 10 | 结构体 | `#StructDeclaration` |
| 11 | 接口 | `#InterfaceDeclaration` |
| 12 | 枚举 | `#EnumDeclaration` |
| 13 | 泛型 | `#Generics` |
| 14 | 集合类型 | `#Collections` |
| 15 | 错误处理 | `#ErrorHandling` |
| 16 | 并发 | `#Concurrency` |
| 17 | 操作符重载 | `#OperatorOverloading` |
| 18 | 模式匹配 | `#PatternMatching` |
| 19 | 包和导入 | `#PackageSystem` |
| 20 | 扩展 | `#Extension` |
| 21 | 宏与注解（概要） | `#MacrosAndAnnotations` |
| 22 | 常量表达式 | `#ConstExpressions` |
| 23 | 入口函数 | `#MainFunction` |
| 24 | 类型转换 | `#TypeConversion` |
| 25 | 属性 | `#Property` |
| 26 | C 互操作 (FFI) | `#CFFI` |
| 27 | 不安全上下文 | `#UnsafeContext` |
| 28 | 宏系统（详细） | `#MacroSystem` |
| 29 | 反射与注解（详细） | `#ReflectionAndAnnotations` |
| 30 | 项目管理 (cjpm) | `#ProjectManagement` |
| 31 | 综合示例 | `#ComprehensiveExample` |

### 3. 实用性导向

每个定义包含：
- **syntax**: 语法模板和示例
- **rules/constraints**: 关键规则和约束
- **examples**: 可运行的代码示例
- **notes**: 常见陷阱提示

### 4. 经过验证的描述

所有语法描述均通过仓颉 SDK 1.0.5 编译验证，确保准确性。验证覆盖了以下核心特性：

- ✅ 基础数据类型（Int/Float/Bool/Rune/String/Unit/Tuple/Array/Range/Option）
- ✅ 变量声明（let/var/const）
- ✅ 函数（普通函数、命名参数、默认值、Lambda、管道操作符）
- ✅ 控制流（if-else、while、for-in、match 模式匹配、if-let）
- ✅ 类（继承、open/override/redef、属性 prop、构造函数、is/as 类型操作、sealed、This 类型）
- ✅ 结构体（值语义、mut 方法、操作符重载、下标操作符、静态成员）
- ✅ 接口（默认实现、多接口实现、sealed interface）
- ✅ 枚举（关联值、递归枚举、成员方法、@Derive）
- ✅ 泛型（泛型类、泛型函数、where 约束）
- ✅ 集合（ArrayList、HashMap、HashSet）
- ✅ 错误处理（自定义异常、try-catch-finally、try-with-resource）
- ✅ 操作符重载（二元、一元、下标 get/set）
- ✅ 扩展（extend）
- ✅ 并发（spawn、Future<T>、AtomicInt64、Mutex、synchronized）
- ✅ 属性（prop/mut prop、static prop、abstract prop）
- ✅ 常量表达式（const func、const init）
- ✅ 类型别名与类型转换
- ✅ 表达式语义（代码块规则、一切皆表达式）
- ✅ 值类型与引用类型（语义区别、let 行为差异）
- ✅ Iterator/Iterable 协议（for-in 脱糖）
- ✅ C 互操作 FFI（foreign 函数、CPointer、CString、类型映射、inout）
- ✅ 不安全上下文（unsafe 函数/块/表达式、传播规则）
- ✅ 宏系统（macro package、quote、嵌套宏、std.ast）
- ✅ 反射与注解（TypeInfo API、自定义注解、溢出注解）
- ✅ 项目管理（cjpm 命令、cjpm.toml 结构、workspace、build script）

### 5. 已验证的关键细节

通过编译验证发现并记录的重要细节：

| 特性 | 正确用法 | 常见错误 |
|------|---------|---------|
| 类继承 | `open class Base` | `class Base`（不加 open 无法继承） |
| Lambda 参数 | `{ x: Int64 => x }` | `{ (x: Int64) => x }` |
| 数组构造 | `Array<Int64>(3, repeat: 0)` | `Array<Int64>(3, item: 0)` |
| 下标 set | `operator func [](i: Int64, value!: T)` | `operator func []=(i, v)` |
| struct 下标 set | `mut operator func [](...)` | `operator func [](...)` |
| ArrayList 添加 | `list.add(item)` | `list.append(item)` |
| HashMap 添加 | `map.add(k, v)` 或 `map[k] = v` | `map.put(k, v)` |
| HashMap 安全读取 | `map.get(key)` 返回 `Option<V>` | `map[key]`（键不存在时崩溃） |
| 主构造函数 | 写在类体内部 `{ ClassName(let x: T) {} }` | 写在类名后 `class C(let x: T)` |
| 捕获 var 的闭包 | 必须直接调用 `{ => count += 1 }()` | 不能赋值给变量 |
| 原子类型 | `AtomicInt64`, `AtomicBool` | `Atomic<Int64>` |

## CUE 设计优势

### 类型约束即文档

```cue
#FunctionDeclaration: {
    kind: "decl"
    parameters: {
        named: {
            syntax:  "func f(value: Int64, indent!: Int64 = 2): String { ... }"
            call:    "f(42, indent: 4)"
            rule:    "命名参数用 ! 标记，调用时用 参数名: 值"
        }
    }
}
```

### 枚举与互斥

```cue
binding: "let" | "var"        // 二选一
throws?: "throws" | "rethrows" // 可选但二选一
```

### 自校验与模块化

可以将各定义在独立的 `.cue` 文件中，通过 `import` 复用。使用 `cue vet` 命令即可验证整个语法描述文件是否自洽。

## 文件结构

```
cangjie.cue    — 仓颉语言核心语法 CUE 描述（已验证）
design.md      — 本设计文档
```
