#import "template/lib.typ": thesis
#import "template/src/abstract.typ": abstract, abstract-en

#let abstract-zh-text = [
  #show: abstract.with(keyword: ("分布式训练", "跨数据中心", "通信优化", "大语言模型"))

  在大语言模型训练中，分布式训练技术已成为支撑大规模模型训练的核心技术基础，其依赖于高性能计算、高性能通信网络和高性能存储架构的协同支持。目前，单数据中心内的计算技术和高性能网络技术已趋于成熟，能够实现高效的计算执行和节点间通信。然而，随着训练数据规模的持续增长，海量数据的收集和清洗已超出单个数据中心的处理能力。在跨数据中心的分布式训练场景中，由于数据中心间缺乏高性能网络互联支撑，节点间的模型同步通信成为制约训练效率的关键瓶颈。

  针对上述挑战，本文从三个层面对跨数据中心分布式训练通信进行系统性优化研究，主要工作内容和创新点如下：

  1. *通信数据量优化*：提出基于1-bit量化的分布式优化器，将通信数据量降低至原有的1/16或1/32，并设计了与之配套的1-bit All-Reduce算法，实现了对1-bit量化张量的高效支持。

  2. *集合通信调度优化*：系统分析了跨数据中心场景下的All-Reduce通信过程，针对NCCL的CollNet通信机制进行改进，提出了多层流水线通信调度策略，充分利用集群间和集群内的异构带宽资源，显著加速通信过程。

  3. *计算-通信重叠优化*：量化分析了混合并行策略下的计算-通信重叠程度，对比了跨数据中心通信与数据中心内部通信的重叠差异，通过重新设计混合并行模式下的梯度同步机制，有效提升了计算-通信的掩盖程度。
]

#let abstract-en-text = [
  #show: abstract-en.with(keyword: ("Distributed Training", "Cross-Data Center", "Communication Optimization", "Large Language Models"))

  In large language model training, distributed training technology has become the fundamental infrastructure supporting large-scale model training, relying on the synergistic support of high-performance computing, high-performance communication networks, and high-performance storage architectures. Currently, computing technology and high-performance networking within a single data center have matured, enabling efficient computation execution and inter-node communication. However, with the continuous growth of training data scale, the collection and processing of massive datasets have exceeded the capacity of single data centers. In cross-data center distributed training scenarios, the lack of high-performance network interconnects between data centers makes inter-node model synchronization communication a critical bottleneck constraining training efficiency. To address these challenges, this thesis conducts systematic optimization research on cross-data center distributed training communication from three perspectives. The main contributions and innovations are as follows:

  1. *Communication Volume Optimization*: We propose a 1-bit quantization-based distributed optimizer that reduces communication volume to 1/16 or 1/32 of the original size, and design a compatible 1-bit All-Reduce algorithm to efficiently support 1-bit quantized tensors.

  2. *Collective Communication Scheduling Optimization*: We systematically analyze the All-Reduce communication process in cross-data center scenarios, improve upon NCCL's CollNet communication mechanism, and propose a multi-level pipeline communication scheduling strategy that fully exploits heterogeneous bandwidth resources between and within clusters, significantly accelerating the communication process.

  3. *Computation-Communication Overlap Optimization*: We quantitatively analyze the degree of computation-communication overlap in hybrid parallelism strategies, compare the overlap differences between cross-data center communication and intra-data center communication, and effectively improve the overlap degree by redesigning the gradient synchronization mechanism in hybrid parallelism mode.
]

#show: thesis.with(
  title: (zh: "面向云边端的跨域分布式训练通信优化研究", en: "Research on Communication Optimization for Distributed Training in Cross-Domain Multi-Data Center Scenarios"),
  author: (zh: "李云潼", en: "Yuntong Li"),
  teacher: (zh: "肖利民", en: "Limin Xiao"),
  teacher-degree: (zh: "教授", en: "Prof."),
  college: (zh: "计算机学院", en: "School of Computer Science and Engineering"),
  major: (
    discipline: "计算机体系结构",
    direction: "模型分布式训练",
    discipline-first: "计算机科学与技术",
    discipline-direction: "计算机体系结构",
  ),
  date: (
    start: "2021年09月01日",
    end: "2026年06月30日",
    summit: "2026年06月10日",
    defense: "2026年06月10日",
  ),
  degree: (zh: "工学硕士", en: "Master of Engineering"),
  lib-number: "TP317",
  stu-id: "SY2306142",
  abstract: abstract-en-text,
  abstract-en: abstract-zh-text,
  bibliography: bibliography.with("ref.bib"),
  achievement: [
    在国际会议上发表了多篇论文，
    参与了多个开源项目的开发，
  ],
  acknowledgements: [
    感谢我的导师肖利民教授的指导和支持

    感谢我的家人和朋友的鼓励和帮助
  ],
  cv: [
    2023年09月 - 2026年06月：北京航空航天大学，计算机科学与技术专业，硕士研究生

    2019年09月 - 2023年06月：北京交通大学，计算机科学与技术专业
  ],
)

= 绪论

== 什么是 Typst？

Typst 是一种现代的文档排版语言，旨在简化文档的编写和排版过程。它结合了编程的灵活性和传统排版的美观，使得用户可以轻松创建高质量的文档。

== 为什么使用 Typst？

使用 Typst 的原因包括：

1、简洁的语法：Typst 的语法设计简洁明了，易于学习和使用。

2、强大的功能：Typst 提供了丰富的功能，如数学公式支持、图形绘制、表格处理等，能够满足各种文档需求。

3、可扩展性：Typst 支持自定义函数和模块，使得用户可以根据自己的需求扩展功能。

#pagebreak()

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
) quad "或" quad mat(
  a_(1,1), a_(1,2), dots.c, a_(1,n);
  a_(2,1), a_(2,2), dots.c, a_(2,n);
  dots.v, dots.v, dots.down, dots.v;
  a_(m,1), a_(m,2), dots.c, a_(m,n);
) $ <matrix-formula>

*方程组*：
$ cases(
  x + y = 1,
  x - y = 0
) => cases(
  x = 1/2,
  y = 1/2
) $ <equation-system>

*向量与箭头*：$arrow(v)$，$hat(x)$，$tilde(x)$，$dot(x)$，$accent(x, dot.double)$，$arrow(A B)$

*希腊字母*：$alpha, beta, gamma, delta, epsilon, zeta, eta, theta, iota, kappa, lambda, mu, nu, xi, pi, rho, sigma, tau, upsilon, phi, chi, psi, omega$

大写：$Gamma, Delta, Theta, Lambda, Xi, Pi, Sigma, Upsilon, Phi, Psi, Omega$

*常用符号*：$in, subset, supset, subset.eq, supset.eq, union, inter, emptyset, times, dot.c, div, plus.minus, equiv, approx, eq.not, lt.eq, gt.eq, infinity, partial, nabla, angle, perp, parallel$

*逻辑符号*：$forall, exists, and, or, not, arrow.r.double, arrow.l.r.double$

*多行公式（对齐）*：
$ f(x) &= x^2 + 2x + 1 \
      &= (x + 1)^2 \
      &= x^2 + 2x + 1 $ <multiline-formula>

== 文献引用

让我们引用两个文献吧 @heDeepResidualLearning2016 @vaswaniAttentionAllYou2023！

#pagebreak()

// Chapter imports (split into per-chapter files)
// Keep the front-matter and import chapters in order

// #include "src/chapters/ch1-intro.typ"
// #include "src/chapters/ch2-elements.typ"
#include "src/chapters/ch3-quantization.typ"
#include "src/chapters/ch4-scheduling.typ"
#include "src/chapters/ch5-overlap.typ"



