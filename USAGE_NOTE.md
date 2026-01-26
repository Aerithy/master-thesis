# 使用本地模板的重要说明

## ⚠️ 重要变更

为了使用 `degree-type` 全局变量功能，你的 `thesis.typ` 文件需要**使用本地模板**而不是预览包。

## 导入方式对比

### ❌ 旧的导入方式（不支持 degree-type）
```typst
#import "@preview/modern-buaa-thesis:0.1.2": abstract, abstract-en, thesis
```

### ✅ 新的导入方式（支持 degree-type）
```typst
// 使用本地模板而不是预览包，以支持 degree-type 参数
#import "template/lib.typ": thesis
#import "template/src/abstract.typ": abstract, abstract-en
```

## 为什么需要这样做？

1. **预览包版本固定**：`@preview/modern-buaa-thesis:0.1.2` 是已发布的包，不包含我们新添加的 `degree-type` 功能。

2. **本地模板已更新**：`template/` 目录下的文件已经更新支持 `degree-type` 参数。

3. **功能可用性**：只有使用本地模板，才能正常使用学位类型全局变量功能。

## 文件结构

```
master-thesis/
├── thesis.typ                    # 你的主文件（已更新导入方式）
├── template/                     # 本地模板目录
│   ├── lib.typ                   # 主模板文件（支持 degree-type）
│   ├── src/
│   │   ├── abstract.typ          # 摘要模块
│   │   ├── cover.typ             # 封面模块（支持 degree-type）
│   │   ├── header-footer.typ     # 页眉页脚（支持 degree-type）
│   │   └── ...
│   └── ...
└── ...
```

## 验证是否生效

编译你的文档后，检查以下位置是否正确显示学位类型：

### 硕士学位（degree-type: "master"）
- ✅ 封面显示：**硕士学位论文**
- ✅ 页眉显示：**北京航空航天大学硕士学位论文**
- ✅ 成果章节：**攻读硕士学位期间取得的成果**

### 博士学位（degree-type: "doctor"）
- ✅ 封面显示：**博士学位论文**
- ✅ 页眉显示：**北京航空航天大学博士学位论文**
- ✅ 成果章节：**攻读博士学位期间取得的成果**

## 如何测试

1. 确保 `thesis.typ` 使用本地导入方式
2. 设置 `degree-type: "doctor"` 
3. 编译文档
4. 检查封面、页眉、附录章节是否显示"博士"相关文本

## 完整示例

```typst
// 使用本地模板
#import "template/lib.typ": thesis
#import "template/src/abstract.typ": abstract, abstract-en

// 定义摘要...
#let abstract-zh-text = [ ... ]
#let abstract-en-text = [ ... ]

// 配置论文
#show: thesis.with(
  title: (zh: "论文标题", en: "Thesis Title"),
  author: (zh: "姓名", en: "Name"),
  // ...其他参数...
  
  degree-type: "doctor",  // 学位类型：master 或 doctor
  degree: (zh: "工学博士", en: "Doctor of Engineering"),
  
  // ...其他参数...
)

// 论文正文...
```

## 常见问题

### Q: 为什么不能继续使用预览包？
A: 预览包是已发布的固定版本，不包含最新的 `degree-type` 功能。要使用新功能，必须使用本地更新的模板。

### Q: 导入路径相对于什么位置？
A: 导入路径相对于 `thesis.typ` 文件所在的目录。如果 `thesis.typ` 和 `template/` 在同一级目录下，使用 `"template/lib.typ"` 即可。

### Q: 如果遇到 "file not found" 错误怎么办？
A: 检查：
1. `template/` 目录是否存在于正确的位置
2. 导入路径是否正确
3. `template/lib.typ` 和 `template/src/abstract.typ` 文件是否存在

### Q: 切换回预览包会怎样？
A: 如果切换回 `@preview/modern-buaa-thesis:0.1.2`，`degree-type` 参数将不被识别，会产生编译错误。

## 总结

✅ 使用本地模板导入 → `degree-type` 功能正常工作  
❌ 使用预览包导入 → `degree-type` 不被识别

确保你的 `thesis.typ` 文件顶部使用本地导入方式！
