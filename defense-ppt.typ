#set page(
  width: 33.867cm,
  height: 19.05cm,
  margin: (x: 1.2cm, y: 0.9cm),
  fill: rgb("#f6f8fb"),
)

#set text(
  font: ("Microsoft YaHei", "Noto Sans CJK SC", "Source Han Sans SC", "Arial"),
  size: 17pt,
  fill: rgb("#1f2937"),
)

#set par(justify: false, leading: 0.85em)

#let accent = rgb("#0f4c81")
#let weak = rgb("#4b5563")
#let divider = rgb("#d5dbe5")

#let slide(title, subtitle: none, body) = [
  #align(left)[
    #text(30pt, weight: "bold", fill: accent)[#title]
    #if subtitle != none [
      #v(0.18cm)
      #text(15pt, fill: weak)[#subtitle]
    ]
  ]
  #v(0.45cm)
  #line(length: 100%, stroke: (paint: divider, thickness: 1.2pt))
  #v(0.45cm)
  #body
  #pagebreak()
]

#let kpi_card(title, value, note: none) = block(
  inset: 12pt,
  radius: 8pt,
  fill: white,
  stroke: (paint: rgb("#d8dee9"), thickness: 0.9pt),
)[
  #text(14pt, fill: weak)[#title]
  #v(0.12cm)
  #text(25pt, weight: "bold", fill: accent)[#value]
  #if note != none [
    #v(0.08cm)
    #text(13pt, fill: weak)[#note]
  ]
]

#slide("面向云边端协同的跨域分布式训练通信优化研究",
  subtitle: "硕士学位论文答辩")[   
  #v(0.9cm)
  #table(
    columns: (1fr, 2fr),
    inset: 8pt,
    align: left,
    stroke: none,
    [答辩人], [李云潼],
    [学号], [SY2306142],
    [专业], [计算机科学与技术（计算机体系结构）],
    [导师], [肖利民 教授],
    [学院], [计算机学院],
    [答辩日期], [2026 年 6 月 10 日],
  )
  #v(0.9cm)
  #text(14pt, fill: weak)[关键词：分布式训练，云边端协同，跨域通信，通信优化，大语言模型]
]

#slide("答辩内容")[
  + 1. 研究背景与问题定义
  + 2. 研究目标与总体方案
  + 3. 工作一：低比特量化通信机制
  + 4. 工作二：层次化流水线集合通信调度
  + 5. 工作三：POLAR-SGD 通信掩盖策略
  + 6. 系统集成与最终实验验证
  + 7. 总结与展望
]

#slide("研究背景：为什么必须做跨域训练通信优化")[
  + 大模型参数规模持续增长（BERT 到 GPT/LLaMA/DeepSeek），训练从单域集群走向云-边-端协同。
  + 跨域网络呈现“域内快、域间慢”：域内可达 100-200 Gb/s，域间常见 10-30 Gb/s，RTT 可达 30-100 ms。
  + 传统扁平化同步假设同构低时延网络，跨域场景下通信直接进入训练关键路径。
  + 结果：GPU 等待通信，吞吐下降，扩展性与成本效率受限。
]

#slide("问题定义：三类核心瓶颈")[
  #grid(
    columns: 3,
    gutter: 14pt,
    [#kpi_card("瓶颈一", "通信量过大", note: "跨域带宽受限，梯度同步体量与参数规模线性耦合")],
    [#kpi_card("瓶颈二", "调度不匹配", note: "扁平 All-Reduce 难以利用分层异构链路")],
    [#kpi_card("瓶颈三", "尾部不可掩盖", note: "高 RTT 下迭代末同步阻塞导致空转")],
  )
  #v(0.45cm)
  #text(14pt, fill: weak)[目标：在不牺牲训练语义与收敛稳定性的前提下，系统性提升端到端训练吞吐。]
]

#slide("总体技术路线：通信量-调度-重叠协同优化")[
  #figure(
    image("image/cloud-edge-device-comm-optimization-system.svg", width: 92%),
    caption: [云边端协同跨域训练通信优化总体框架],
  )
  #v(0.2cm)
  + 模块 1（第 3 章）：低比特量化压缩，降低跨域传输载荷。
  + 模块 2（第 4 章）：层次化流水线调度，提升链路利用与并发。
  + 模块 3（第 5 章）：前缀触发异步同步，消减迭代尾部纯等待。
]

#slide("论文创新点")[
  + 提出支持 $b in \{1,2,4,8,16\}$ 的 k-bit 随机舍入量化机制，并结合位打包与误差补偿。
  + 提出“域内归约-域间归约-域内广播”三阶段分块流水化调度与双流并行执行。
  + 提出 POLAR-SGD：在每步一次同步语义下，将 All-Reduce 触发点前移并引入预测误差修正。
  + 将三类方法集成为统一运行时控制闭环，实现可监测、可回退、可部署。
]

#slide("工作一：低比特量化通信机制")[
  #columns(2)[
    #figure(
      image("image/ch3-kbit-quantization-workflow.svg", width: 100%),
      caption: [k-bit 量化工作流],
    )

    #colbreak()

    + 动量归一化 + 随机舍入，实现无偏低比特表示。
    + 位打包（bit-packing）降低有效字节，减少跨域传输量。
    + 误差反馈补偿量化扰动，保障收敛稳定。
    + 低侵入集成到现有分布式训练循环。
  ]
]

#slide("工作一实验结果：通信压缩与收敛稳定")[
  #grid(
    columns: 2,
    gutter: 14pt,
    [#figure(image("image/ch3-experiment-results.svg", width: 100%), caption: [不同带宽下吞吐增益])],
    [#figure(image("image/ch3-validation-loss-curve.svg", width: 100%), caption: [验证损失曲线对比])],
  )
  #v(0.25cm)
  + 在受限链路下，通信量最高压缩至原始 1/32。
  + $b=4$ 时相对 FP32 吞吐提升：10,000/1,000/100 Mb/s 分别约 1.28x/1.58x/2.43x。
  + 多模型端到端结果保持稳定增益，验证损失差值控制在约 0.02 以内。
]

#slide("工作二：层次化流水线集合通信调度")[
  #columns(2)[
    #figure(
      image("image/ch4-hierarchical-topology.svg", width: 100%),
      caption: [层次化通信拓扑],
    )
    #figure(
      image("image/ch4-multistream-hierarchical-allreduce.png", width: 100%),
      caption: [双流并行与流水线机制],
    )
    #colbreak()
    + All-Reduce 分解为域内归约、域间归约、域内广播。
    + 张量分块后执行预热-主流水-冷却，提升阶段重叠率。
    + 通过独立通信流与事件依赖降低串行等待。
    + 使“域内快、域间慢”拓扑得到充分利用。
  ]
]

#slide("工作二实验结果：通信时延与端到端加速")[
  #grid(
    columns: 2,
    gutter: 14pt,
    [#figure(image("image/ch4-e2e-results.svg", width: 100%), caption: [端到端性能对比])],
    [#figure(image("image/ch4-chunk-sensitivity.svg", width: 100%), caption: [块大小敏感性])],
  )
  #v(0.2cm)
  + 通信耗时由 128.5 ms 降至 74.1 ms，较原生路径降低 42.3%。
  + GPU 利用率由 68% 提升到 89%。
  + 端到端吞吐由 4,602 提升至 6,216 items/s，加速比约 1.35x。
  + 在带宽不对称、高 RTT 场景下收益更明显。
]

#slide("工作三：POLAR-SGD 通信掩盖策略")[
  #columns(2)[
    #figure(
      image("image/polar-pp-timeline.png", width: 100%),
      caption: [前缀触发异步同步时序],
    )
    #colbreak()
    + 背景：DP+PP 下迭代末 All-Reduce 尾部阻塞显著。
    + 核心：引入截断点 $tau$，前移触发异步同步。
    + 对未完成梯度做前缀缩放，并用误差反馈修正。
    + 保持“每迭代一次全局同步”语义。
  ]
]

#slide("工作三实验结果：吞吐、收敛与敏感性")[
  #grid(
    columns: 2,
    gutter: 14pt,
    [#figure(image("image/polar_network_sensitivity.png", width: 100%), caption: [网络敏感性])],
    [#figure(image("image/ch6-system-loss-curves.svg", width: 100%), caption: [收敛一致性参考])],
  )
  #v(0.2cm)
  + 在 30 Gb/s、50 ms RTT 约束下，POLAR-SGD 吞吐 66,104 tokens/s，较基线 35,350 提升 1.87x。
  + 与 DiLoCo 相比，在保持步级同步语义下仍取得更高吞吐。
  + 消融实验表明：梯度缩放与误差反馈均为稳定性关键组件。
]

#slide("系统集成：三模块协同运行时")[
  #figure(
    image("image/three-module-communication-optimization-mechanism.svg", width: 92%),
    caption: [三模块协同通信优化机制],
  )
  #v(0.2cm)
  + 运行时闭环：监测 -> 判定 -> 执行 -> 反馈。
  + 按链路状态动态启停/调参，提供可解释回退路径。
  + 保证训练语义一致性与工程稳定性。
]

#slide("最终系统级验证结果")[
  #grid(
    columns: 3,
    gutter: 12pt,
    [#kpi_card("弱受限网络", "1.78x", note: "10-30 Gb/s, 5-30 ms")],
    [#kpi_card("中度受限网络", "2.85x", note: "1-10 Gb/s, 30-100 ms")],
    [#kpi_card("强受限网络", "4.39x", note: "10-200 Mb/s, 5-30 ms")],
  )
  #v(0.35cm)
  #figure(
    image("image/ch6-system-performance-compare.svg", width: 94%),
    caption: [本系统与现有训练系统性能对比],
  )
]

#slide("系统稳定性与退化行为")[
  #grid(
    columns: 2,
    gutter: 14pt,
    [#figure(image("image/ch6-system-loss-curves.svg", width: 100%), caption: [step/time 对齐 loss 曲线])],
    [#figure(image("image/ch6-system-degradation.svg", width: 100%), caption: [高带宽低 RTT 下自动回退])],
  )
  #v(0.2cm)
  + 最终验证损失差值控制在 0.05 以内，未见明显收敛漂移。
  + 高带宽低 RTT 条件下自动回退，避免无效优化开销。
]

#slide("综合对比与结论")[
  #table(
    columns: (1.5fr, 1.2fr, 1.2fr, 1.3fr),
    align: center,
    table.header([优化层面], [核心问题], [关键结果], [工程价值]),
    [通信量压缩], [跨域载荷大], [最高 1/32 压缩，吞吐最高 2.43x], [适配受限带宽链路],
    [调度重排], [层次拓扑不匹配], [通信耗时 -42.3%，端到端 1.35x], [提升链路利用与GPU利用率],
    [通信掩盖], [迭代尾部阻塞], [吞吐 1.87x，语义保持], [减少纯等待窗口],
    [系统协同], [单点优化难闭环], [系统级最高 4.39x], [可运行、可回退、可部署],
  )
]

#slide("总结")[
  + 本文围绕跨域训练三类瓶颈，提出“压缩-调度-重叠”协同通信优化框架。
  + 在多组网络条件和多模型任务上验证了稳定吞吐增益与收敛一致性。
  + 系统级实验表明：网络越受限，协同优化收益越显著，最高达到 4.39x。
  + 形成了面向云边端协同大模型训练的可落地方法与工程实现路径。
]

#slide("展望")[
  + 面向更深层级拓扑（多云-多边-多端）扩展分层调度与策略空间。
  + 引入更细粒度在线策略学习，实现动态位宽与分块自适应。
  + 与 MoE、长上下文训练等新负载进一步协同优化。
  + 推进跨域训练系统在真实业务场景中的持续部署验证。
]

#align(center + horizon)[
  #v(4.8cm)
  #text(45pt, weight: "bold", fill: accent)[谢谢各位老师]
  #v(0.4cm)
  #text(26pt, fill: weak)[敬请批评指正]
]