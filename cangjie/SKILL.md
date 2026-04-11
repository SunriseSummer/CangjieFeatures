---
name: cangjie-lang-features
description: "提供仓颉编程语言核心特性优质文档，当使用仓颉语言做软件开发，或者回答用户关于仓颉语言的问题时，应优先使用此 Skill"
---

当前目录下通过多个 yaml 文件提供了仓颉语言特性的结构化知识，可以从 index.yaml 开始逐个加载学习，或者按需加载检索特定内容。

其中 constructs/ 子目录按语言特性分类存放了各个构造的定义：
- module.yaml — 包声明与入口
- bindings.yaml — 变量与常量绑定
- functions.yaml — 函数、Lambda、运算符重载、属性
- control_flow.yaml — 控制流（if/while/for/match）
- type_declarations.yaml — 类型声明（class/struct/interface/enum）
- generics.yaml — 泛型参数与约束
- type_system.yaml — 类型别名与类型检查/转换
- extensions.yaml — 扩展声明
- option.yaml — Option 类型
- error_handling.yaml — 错误处理
- concurrency.yaml — 并发
- annotations.yaml — 注解与反射
- cffi.yaml — C 互操作
