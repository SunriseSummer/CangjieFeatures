---
name: cangjie-lang-features
description: "提供仓颉编程语言核心特性优质文档，当使用仓颉语言做软件开发，或者回答用户关于仓颉语言的问题时，应优先使用此 Skill"
---

1. [词法元素](01_lexical.yaml) — 关键字，标识符，运算符优先级，字面量
2. [类型系统](02_type_system.yaml) — 类型层次，内建类型，元组，数组，区间，函数类型，Option，类型转换，子类型规则
3. [变量与表达式](03_variables_and_expressions.yaml) — 变量声明，解构赋值，作用域，控制流表达式，循环控制，区间
4. [函数](04_functions.yaml) — 函数声明，命名参数，Lambda 与闭包，尾随 Lambda，管道与组合运算符，运算符重载
5. [类](05_classes.yaml) — 类定义，构造函数，终结器，单继承，抽象类，属性，访问修饰符
6. [结构体](06_structs.yaml) — 结构体定义，值语义，mut 函数与可变性规则，接口实现
7. [接口](07_interfaces.yaml) — 接口定义，默认实现，接口继承，sealed 接口，Any 接口
8. [枚举](08_enums.yaml) — 枚举定义，构造器，递归枚举，成员函数，相等性
9. [模式匹配](09_pattern_matching.yaml) — match 表达式，模式类型，模式守卫，if-let/while-let，可反驳性
10. [泛型](10_generics.yaml) — 泛型函数/类/接口/枚举，约束，型变
11. [错误处理](11_error_handling.yaml) — 异常层次，try/catch/finally，try-with-resources，Option 型错误处理
12. [并发编程](12_concurrency.yaml) — 线程模型，spawn，Future，原子操作，Mutex，synchronized，条件变量
13. [类型扩展](13_extensions.yaml) — 直接扩展，接口扩展，泛型扩展，孤儿规则
14. [包机制](14_packages.yaml) — 包声明，import 导入，访问修饰符，main 入口
15. [宏](15_macros.yaml) — 宏包，Token/Tokens，quote 表达式，属性宏，AST 节点解析
16. [C 互操作](16_ffi.yaml) — foreign 函数，类型映射，unsafe 块，inout 参数，LibC 内存管理
17. [反射与注解](17_reflection_and_annotations.yaml) — 溢出注解，自定义注解，运行时反射
18. [项目管理](18_project_init_build_run.yaml) — cjpm 命令，项目结构，cjpm.toml 配置，依赖管理
19. [单元测试](19_unit_test.yaml) — 断言宏，生命周期钩子，参数化测试，Mock 框架，基准测试
