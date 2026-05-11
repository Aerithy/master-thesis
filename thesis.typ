#import "template/lib.typ": thesis
#import "template/src/abstract.typ": abstract, abstract-en

#let abstract-zh-text = [
  #show: abstract.with(keyword: ("分布式训练", "云边端协同", "跨域通信", "通信优化", "大语言模型"))

  分布式训练技术已成为支撑大规模模型训练的核心基础。随着模型参数量与训练数据的指数级增长，单机单卡乃至同构集群已难以满足高效训练的资源与存储需求。为了缓解单一数据中心的算力资源压力并避免海量数据跨地域搬移，训练数据与算力资源正在从“单一数据中心”向“云-边-端协同”的跨域形态演进。然而，在跨域分布式场景下分布式训练系统面临着，跨域链路异构、域间网络带宽低、延时高且抖动显著的问题。导致在跨域分布式训练场景下，跨域数据并行中的梯度同步操作极易成为系统的性能瓶颈，使得算力资源大量闲置。

  针对上述通信瓶颈挑战，本文以“跨域分布式训练通信优化”为目标，从减小通信规模、调度集合通信、实现计算-通信重叠层面展开系统性研究，提出了一套高效的跨域协同训练优化方案：

  （1）通信数据规模优化层面：针对跨域受限链路下数据交换载荷过大导致的训练吞吐受限问题，提出分布式优化器低比特量化方法。首先，通过 k-bit 随机舍入量化分布式压缩机制，将连续浮点梯度映射为低比特表示的有限的离散数值；其次，通过带有残差补偿的量化同步与聚合算法，以缓解位宽降低带来的累积噪声。优化了单次同步的通信带宽开销，在受限网络下将单次通信量最高压缩至原规模的 1/32，在保障收敛稳定性的同时，在 100 Mb/s 低带宽场景下将端到端吞吐量提升了 2.43 倍。

  （2）集合通信调度优化层面：针对跨域链路中跨域链路异构且域间网络带宽低导致的训练中集合通信执行效率低的问题，提出基于流水线的层次化梯度通信调度策略。首先，通过引入分层集合通信算法，将全局各节点的全归约通信分解为域内归约、跨域传输与域内广播三个阶段，降低了域间通信量；其次，通过引入张量分块级的流水线机制，将域内规约、跨域传输与域内广播三阶段按切分的张量块流水执行，优化了跨域链路间通信时域内链路的利用率。优化了跨域异构集群间数据聚合的调度重叠率，充分利用了域内部的高速带宽，跨域梯度同步通信耗时降低了 42.3%，进而使端到端训练吞吐量提升了 1.35 倍。

  （3）计算通信重叠层面：针对跨域训练在单次迭代末尾极易产生不可掩盖的阻塞式同步尾延迟问题，提出面向通信受限场景下的混合并行通信掩盖策略。首先，通过在反向传播阶段提前触发非阻塞集合通信，为梯度同步的长尾部预留足够的计算掩盖窗口；其次，利用张量缩放策略，来预测推算尚未计算完成的梯度数据并将其纳入跨域梯度同步，降低由于提前触发通信导致的梯度数据尺度不一致的问题；最后，利用轻量级的误差反馈反馈，将预测梯度值与剩余梯度的偏差延迟补偿至下一计算迭代，去除了由于使用仅部分数据的梯度信息产生的信息损失。该层面优化了设备本地计算时间与跨域通信时长的掩盖比率，最终成功消除了由跨域 All-Reduce 造成的尾部纯等待空窗，在维持“每迭代一次全局同步”语义的前提下将端到端训练吞吐量提升至未优化基线的 1.87 倍。

  本文的系统集成方案在多节点 GPU 集群中进行了验证，依托网络控制复现了真实的跨域受限链路条件，并针对上述三个层面实现了各层面协同运行的通信优化框架。端到端评估测试表明，本优化框架能够将面向云边端协同模型训练系统吞吐量提升至未优化基线的 4.35 倍；且在模型收敛精度与损失（Loss）预测曲线上与传统全同步梯度下降方案保持高度一致，在维持模型质量的前提下大幅降低了跨域瓶颈损耗。
]

#let abstract-en-text = [
  #show: abstract-en.with(keyword: ("Distributed Training", "Cloud-Edge-Device Collaboration", "Cross-Domain Communication", "Communication Optimization", "Large Language Models"))

  Distributed training is the fundamental infrastructure for scaling large language models. To alleviate GPU resource pressure in single datacenters and avoid migrating massive data across regions, resources are shifting towards a "cloud-edge-device" collaborative paradigm. However, training systems under this paradigm face severe network heterogeneity: while intra-domain links offer high bandwidth and low latency, cross-domain links suffer from significantly lower bandwidth, higher latency, and larger jitter. Consequently, the blocking gradient synchronization operations across domain clusters become a severe performance bottleneck, underutilizing available computation resources.

  To address this bottleneck, this thesis targets communication optimization for cross-domain distributed training and conducts systematic research spanning three interrelated aspects: transmission volume, collective scheduling, and computation-communication overlap. The main contributions and proposed mechanisms are as follows:

  (1) *Communication Volume Optimization*: Targeting the network transmission bottleneck caused by massive data exchange payloads over cross-domain constrained links. First, we introduce continuous exponential moving average and adaptive normalization to smooth historical gradients. Next, we propose a k-bit stochastic rounding distributed compression mechanism ($b in {1, 2, 4, 8, 16}$) to map floating-point gradients to discrete levels. Finally, we design a quantized synchronization procedure intertwined with compensations to mitigate cumulative noises. This optimizes the communication bandwidth boundaries per synchronization, ultimately compressing the payload by up to 32x and increasing the end-to-end throughput by 2.43x under extremely low-bandwidth (100 Mb/s) scenarios while guaranteeing convergence stability.

  (2) *Collective Communication Scheduling*: Targeting the execution inefficiency and hardware underutilization induced by conventional flat synchronization primitives operating on the asymmetric "fast intra-domain, slow inter-domain" topology. First, we logically decouple global communications into intra-domain reduction, inter-domain communication, and intra-domain broadcast. Second, we orchestrate a tensor-chunking pipeline mechanism powered by dual-stream concurrency. Finally, fine-grained event dependencies are seamlessly injected into the operator backend. This optimizes the scheduling overlap ratio for heterogeneous aggregations, ultimately reducing the cross-node gradient synchronization time by 42.3% and improving the end-to-end training throughput by 1.35x.

  (3) *Computation-Communication Overlap*: Targeting the inescapable blocking synchronization tail generated at the tail-end of hybrid parallel (DP+PP) training iterations. First, we pinpoint the safety window and trigger prefix-based non-blocking collective communication operations (POLAR-SGD) early inside backward passes. Then, tensor extrapolations are operated to scale the incomplete prefix gradients for global coordination. Finally, an agile residual error loop securely compensates prediction deviations onto following schedules. This optimizes the temporal masking ratio between localized computations and global broadcasts, successfully eliminating pure-stalled cross-domain All-Reduce deadlocks and remarkably hiking the end-to-end training throughput to 1.87x of the unoptimized baseline under intact "sync-per-iteration" semantics.

  End-to-end evaluations on multi-node GPU clusters under emulated authentic cross-domain link constraints (30 Gb/s bandwidth and 50 ms latency) validate the system integration. Experiments demonstrate that the integrated framework achieves a 1.78 \~ 4.35x improvement in training throughput compared to the standard synchronous baseline. Furthermore, it produces convergence trajectories almost identical to traditional synchronous methods without degrading model quality, showcasing efficient and robust large model training for cross-domain collaborations.
]

#show: thesis.with(
  title: (zh: "面向云边端协同的跨域分布式训练通信优化研究", en: "Research on Communication Optimization for Cross-Domain Distributed Training Toward Cloud-Edge-Device Collaboration"),
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
  abstract: abstract-zh-text,
  abstract-en: abstract-en-text,
  bibliography: bibliography.with("supplementary/bib.bib"),
  achievement: [
    围绕云边端跨域分布式训练场景下的通信瓶颈问题开展了系统性研究，提出了低比特量化压缩、分层流水线集合通信调度以及计算与通信重叠等关键优化方法，并完成了系统的设计与验证。

    独立完成了跨域分布式实验平台的搭建、核心优化算法的工程实现与性能调优，并通过详实的实验论证了本文提出方法的有效性。

    在读期间，围绕本文核心研究内容，已录用高水平学术论文一篇。

    申请国家发明专利一项。
  ],
  acknowledgements: [
    行文至此，三载硕士生涯即将画上句号。在此，诚挚感谢我的导师肖利民教授。从最初的课题探索、研究思路的梳理，到最终论文的字斟句酌，肖老师渊博的学识、严谨的治学态度和对科研的满腔热忱，始终是我前行路上的灯塔与榜样。

    感谢课题组的各位老师和同门。在无数个日夜的算法推演、系统调试与论文研讨中，是你们提供了无私的帮助与宝贵的建议，为我营造了包容且充满活力的学术氛围。

    感谢北京航空航天大学计算机学院为我提供了卓越的研究平台、充足的学术资源以及悉心的生活保障，使我得以心无旁骛地探索未知。

    最后，向我的家人与朋友们致以最深切的谢意。感谢你们一直以来的默默付出、包容与鼓励，是你们无条件的爱与支持，赋予我克服困难、不断前行的勇气与力量。
  ],
  cv: [
    2023年09月 - 2026年06月：北京航空航天大学，计算机科学与技术专业，硕士研究生

    2019年09月 - 2023年06月：北京交通大学，计算机科学与技术专业
  ],
)

// Chapter imports (split into per-chapter files)
// Keep the front-matter and import chapters in order

#include "src/chapters/ch1-intro.typ"
#include "src/chapters/ch2-background.typ"
#include "src/chapters/ch3-quantization.typ"
#include "src/chapters/ch4-scheduling.typ"
#include "src/chapters/ch5-overlap.typ"
#include "src/chapters/ch6-system-integration.typ"



