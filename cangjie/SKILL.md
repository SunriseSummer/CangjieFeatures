# 仓颉语言 YAML 知识库索引

> 本目录包含仓颉（Cangjie）编程语言的核心特性文档，以 YAML 格式编写，供 AI 高效学习和掌握仓颉语言。

---

## 基础语法

- **[01 — 词法元素](01_lexical.yaml)**：关键字、标识符、运算符优先级（0-18 级）、字面量（整数/浮点/布尔/Rune/字符串/数组/元组/区间）
- **[02 — 类型系统](02_type_system.yaml)**：类型层次（Any/Nothing/Object）、内建类型、元组、数组（Array/VArray）、区间、函数类型、`Option<T>`、类型转换与子类型规则、类型别名
- **[03 — 变量与表达式](03_variables_and_expressions.yaml)**：变量声明（let/var/const）、解构赋值、作用域、控制流表达式（if/while/for-in/match）、循环控制、区间与赋值

## 函数与类型定义

- **[04 — 函数](04_functions.yaml)**：函数声明、命名参数与默认值、Lambda 与闭包（含可变捕获限制）、尾随 Lambda、函数类型、管道（|>）与组合（~>）运算符、运算符重载、const 函数、嵌套函数
- **[05 — 类](05_classes.yaml)**：类定义（引用类型）、成员变量、构造函数（init/主构造函数）、终结器（~init）、单继承（需 open 标记）、sealed 继承、override/redef、抽象类、属性（prop）、This 类型、访问修饰符
- **[06 — 结构体](06_structs.yaml)**：结构体定义（值类型）、构造函数、值语义与拷贝行为、mut 函数与可变性规则、属性、接口实现与装箱行为、使用限制
- **[07 — 接口](07_interfaces.yaml)**：接口定义、抽象方法与默认实现、属性、静态成员、接口继承（单/多/菱形）、class/struct 实现规则、mut 函数交互、sealed 接口、Any 接口
- **[08 — 枚举](08_enums.yaml)**：枚举定义（代数数据类型）、有参/无参构造器、同名构造器、递归枚举、枚举成员函数、接口实现、相等性（@Derive[Equatable]）、泛型枚举

## 高级特性

- **[09 — 模式匹配](09_pattern_matching.yaml)**：match 表达式、模式类型（常量/通配符/绑定/元组/类型/枚举）、模式守卫（where）、嵌套模式、if-let/while-let、let 与 for-in 中的模式、可反驳性
- **[10 — 泛型](10_generics.yaml)**：泛型函数/类/结构体/接口/枚举、约束（where）、多重约束、型变（不变/协变/逆变）、类型参数作用域、实例化
- **[11 — 错误处理](11_error_handling.yaml)**：异常层次（Error/Exception）、自定义异常、throw、try/catch/finally、try-with-resources、catch 模式、Option 型错误处理、最佳实践
- **[12 — 并发编程](12_concurrency.yaml)**：M:N 线程模型、spawn 创建线程、`Future<T>`、sleep/Duration（核心包，无需导入）、原子操作（AtomicInt64 等）、Mutex、synchronized、条件变量、ThreadLocal、SyncCounter、协作取消
- **[13 — 类型扩展](13_extensions.yaml)**：直接扩展（extend）、接口扩展、泛型扩展、扩展中的访问与可见性规则、孤儿规则

## 模块与工具链

- **[14 — 包机制](14_packages.yaml)**：包声明与目录映射、import 导入、重新导出（public import）、访问修饰符（private/internal/protected/public）、main 入口、cjpm 概览
- **[15 — 宏](15_macros.yaml)**：宏包、Token/Tokens 类型、quote 表达式与插值、非属性宏、属性宏、AST 节点解析、宏嵌套
- **[16 — C 互操作](16_ffi.yaml)**：foreign 函数声明、类型映射（基础类型/指针/CFunc）、unsafe 块、inout 参数、@C 注解、LibC 内存管理
- **[17 — 反射与注解](17_reflection_and_annotations.yaml)**：整数溢出注解（@OverflowThrowing/Wrapping/Saturating）、自定义注解（@Annotation）、运行时反射（ClassTypeInfo/TypeInfo）
- **[18 — 项目管理](18_project_init_build_run.yaml)**：cjpm 命令（init/build/run/test/bench/clean）、项目结构、cjpm.toml 配置、工作区、依赖管理、构建/测试/性能分析选项、交叉编译
- **[19 — 单元测试](19_unit_test.yaml)**：@Test/@TestCase、断言宏（@Assert/@Expect）、生命周期钩子、参数化测试、测试配置（标签/跳过/超时/并行）、Mock 框架、动态测试、基准测试

---

> 基于仓颉 SDK 1.0.5 验证。所有代码示例均通过编译测试。
