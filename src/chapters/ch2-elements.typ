= 支持的文档元素

== 图片引用

如@fig:logo 所示，我们在文档中插入一个图片，并为其添加了一个标题。

#figure(
  image("logo.png", width: 30%),
  caption: "这是一个北航的Logo",
) <fig:logo>

== 表格引用

如@tab:three-line 所示，我们在文档中插入一个三线表格，并为其添加了一个标题。

#figure(
  table(
    stroke: none,
    columns: (1fr, 1fr, 1fr, 1fr),
    align: center,
    table.hline(),
    table.header([*标题1*], [*标题2*], [*标题3*], [*标题4*]),
    table.hline(stroke: 0.5pt),
    [内容1], [内容1], [内容1], [内容1],
    [内容2], [内容2], [内容2], [内容2],
    [内容3], [内容3], [内容3], [内容3],
    [内容4], [内容4], [内容4], [内容4],
    table.hline(),
  ),
  caption: "这是一个三线表",
) <tab:three-line>

== 数学公式

这是一个行内公式：$E = m c^2$

这是一个行间公式（@mc2）：

$ E = m c^2 $ <mc2>

=== 更多数学公式示例

*上下标和分数*：$x^2 + y^2 = z^2$，$x_i^2$，分数 $a/b$ 或 $frac(a, b)$

*根号*：$sqrt(x)$，$sqrt(x^2 + y^2)$，$n$ 次根号 $root(n, x)$

*求和与积分*：
$ sum_(i=1)^n i = frac(n(n+1), 2) $ <sum-formula>

$ integral_0^infinity e^(-x) dif x = 1 $ <integral-formula>

*极限*：
$ lim_(x -> infinity) (1 + 1/x)^x = e $ <limit-formula>

*矩阵*：
$ mat(
  a, b;
  c, d;
) $ <matrix-formula>

*方程组*：
$ cases(
  x + y = 1,
  x - y = 0
) $ <equation-system>

*多行公式（对齐）*：
$ f(x) &= x^2 + 2x + 1 \
      &= (x + 1)^2 \
      &= x^2 + 2x + 1 $ <multiline-formula>

== 文献引用

让我们引用两个文献吧 @heDeepResidualLearning2016 @vaswaniAttentionAllYou2023！

#pagebreak()
