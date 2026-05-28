#import "template/lib.typ": thesis
#import "template/src/abstract.typ": abstract, abstract-en
#import "template/src/constant.typ": font-size, font-type

#let abstract-zh-text = [
  #show: abstract.with(keyword: ("分布式训练", "云边端协同", "跨域通信", "通信优化", "大语言模型"))

  分布式训练技术已成为支撑大规模模型训练的核心基础。随着模型参数量与训练数据的指数级增长，单机单卡乃至同构集群已难以满足高效训练的资源与存储需求。为了缓解单一数据中心的算力资源压力并避免海量数据跨地域搬移，训练数据与算力资源正在从“单一数据中心”向“云-边-端协同”的跨域形态演进。然而，在跨域分布式场景下分布式训练系统面临着跨域链路异构、域间网络带宽低、延时高且抖动显著的问题。导致在跨域分布式训练场景下，跨域并行训练中的通信操作极易成为系统的性能瓶颈，使得算力资源大量闲置。

  针对上述通信瓶颈挑战，本文以“降低跨域同步在训练关键路径中的暴露开销”为核心目标，从通信数据规模压缩、集合通信调度重排、计算-通信深度重叠三个层面展开系统性研究，提出一套面向云边端跨域训练的协同通信优化方案：

  （1）通信数据规模优化层面：针对跨域受限链路下数据交换载荷过大导致的训练吞吐受限问题，提出分布式优化器低比特量化方法。首先，通过 k-bit 随机舍入量化分布式压缩机制，将连续浮点梯度映射为低比特表示的有限离散数值；其次，通过带有残差补偿的量化同步与聚合算法，缓解位宽降低带来的累积噪声。该方法从源头降低跨域同步的数据体积，在受限网络下将单次通信量最高压缩至原规模的 1/32，在保障收敛稳定性的同时，在 100 Mb/s 低带宽场景下将端到端吞吐量提升了 2.43 倍。

  （2）集合通信调度优化层面：针对跨域链路异构且域间网络带宽低导致集合通信执行效率低的问题，提出基于流水线的层次化梯度通信调度策略。首先，将全局全归约通信分解为域内归约、跨域传输与域内广播三个阶段，降低域间慢链路上的通信压力；其次，引入张量分块级流水线机制，使三阶段按张量块并发接力执行，充分利用域内高速链路掩盖跨域传输等待。该方法优化了跨域异构集群间数据聚合的调度重叠率，使跨域梯度同步通信耗时降低 42.3%，进而使端到端训练吞吐量提升 1.35 倍。

  （3）计算通信重叠层面：针对跨域训练在单次迭代末尾极易产生不可掩盖的阻塞式同步尾延迟问题，提出面向通信受限场景下的混合并行通信掩盖策略。首先，在反向传播阶段提前触发非阻塞集合通信，为梯度同步预留更长的计算掩盖窗口；其次，利用张量缩放策略预测尚未计算完成的梯度数据并将其纳入跨域同步，降低提前触发导致的梯度尺度偏差；最后，利用轻量级误差反馈，将预测梯度与完整梯度之间的偏差延迟补偿至下一迭代。该方法在维持“每迭代一次全局同步”语义的前提下，将跨域 All-Reduce 从迭代尾部关键路径中移除，使端到端训练吞吐量提升至未优化基线的 1.87 倍。

  本文的系统集成方案在多节点 GPU 集群中进行了验证，依托网络控制复现真实的跨域受限链路条件，并将上述三个层面的机制整合为可协同运行的通信优化框架。端到端评估表明，本优化框架能够将面向云边端协同的模型训练吞吐量提升至未优化基线的 3.85 至 6.41 倍；同时，模型收敛精度与损失曲线与传统全同步训练保持高度一致，在维持模型质量的前提下显著降低跨域同步瓶颈。
]

#let abstract-en-text = [
  #show: abstract-en.with(keyword: ("Distributed Training", "Cloud-Edge-Device Collaboration", "Cross-Domain Communication", "Communication Optimization", "Large Language Models"))

  Distributed training is the fundamental infrastructure for scaling large language models. To alleviate GPU resource pressure in single datacenters and avoid migrating massive data across regions, resources are shifting towards a "cloud-edge-device" collaborative paradigm. However, training systems under this paradigm face severe network heterogeneity: while intra-domain links offer high bandwidth and low latency, cross-domain links suffer from significantly lower bandwidth, higher latency, and larger jitter. Consequently, the blocking gradient synchronization operations across domain clusters become a severe performance bottleneck, underutilizing available computation resources.

  To address this bottleneck, this thesis aims to reduce the exposed cost of cross-domain synchronization on the training critical path. It conducts systematic research across three interrelated aspects: transmission-volume reduction, topology-aware collective scheduling, and computation-communication overlap. The main contributions are as follows:

  (1) *Communication Volume Optimization*: We propose a k-bit stochastic-rounding compression mechanism ($b in {1, 2, 4, 8, 16}$) with bit packing, quantized aggregation, and residual compensation. It reduces the payload of each cross-domain synchronization by up to 32x and improves end-to-end throughput by 2.43x under a 100 Mb/s constrained link while preserving convergence stability.

  (2) *Collective Communication Scheduling*: We propose a pipelined hierarchical All-Reduce scheduler for the asymmetric "fast intra-domain, slow inter-domain" topology. The method decomposes synchronization into intra-domain reduction, inter-domain transfer, and intra-domain broadcast, and further pipelines tensor chunks with dual-stream concurrency. It reduces cross-domain gradient synchronization time by 42.3% and improves end-to-end training throughput by 1.35x.

  (3) *Computation-Communication Overlap*: We propose a prefix-triggered non-blocking All-Reduce mechanism for hybrid DP+PP training. It starts cross-domain synchronization before the iteration tail, scales incomplete prefix gradients, and uses residual error feedback to compensate prediction deviations in later iterations. Under intact "one global synchronization per iteration" semantics, it removes the exposed All-Reduce waiting tail and improves end-to-end throughput to 1.87x of the unoptimized baseline.

  End-to-end evaluations on multi-node GPU clusters under emulated cross-domain link constraints validate the integrated framework. Experiments demonstrate a 3.85 \~ 6.41x throughput improvement over the standard synchronous baseline while preserving convergence trajectories close to full synchronization, demonstrating efficient and robust large-model training for cross-domain collaboration.
]

#show: thesis.with(
  title: (zh: "面向云边端协同的跨域分布式训练通信优化研究", en: "Research on Communication Optimization for Cross-Domain Distributed Training Toward Cloud-Edge-Device Collaboration"),
  author: (zh: "李云潼", en: "Yuntong Li"),
  teacher: (zh: "肖利民", en: "Limin Xiao"),
  teacher-degree: (zh: "教授", en: "Prof."),
  college: (zh: "计算机学院", en: "School of Computer Science and Engineering"),
  major: (
    discipline: "计算机科学与技术",
    direction: "模型分布式训练",
    discipline-first: "计算机科学与技术",
    discipline-direction: "计算机体系结构",
  ),
  date: (
    start: "2023年09月01日",
    end: "2026年05月29日",
    summit: "2026年05月08日",
    defense: "2026年05月25日",
  ),
  degree: (zh: "工学硕士", en: "Master of Engineering"),
  lib-number: "TP317",
  stu-id: "SY2306142",
  abstract: abstract-zh-text,
  abstract-en: abstract-en-text,
  bibliography: read("supplementary/bib.bib"),
  achievement: [
    #set par(
      justify: true,
      // leading: 1em,
      // spacing: 1em,
      first-line-indent: 0em,
      hanging-indent: 1.5em,
    )

    == 攻读硕士学位期间取得的创新成果

    [1] *Yuntong Li*, Limin Xiao, Zhisheng Huo, Jinquan Wang, Zhibin Jia, Li Ruan, Lun Li.  FusionTransmit: A Compression-Aware Distributed Training Scheduler for PowerSGD[J]. CCF Transactions on High Performance Computing, 2026-03-03. (CCF C, 已录用)

    [2] Runnan Shen, Jinquan Wang, Zhisheng Huo, Limin Xiao, Shengyang Tan, *Yuntong Li*, Lun Li, Xiangrong Xu, Liang Wang. A two-stage data placement strategy for cloud-edge-device collaborative environment[J]. COMPUTER COMMUNICATIONS, 2026-04-27

    [3] 肖利民，沈润楠，王锦权，霍志胜，谭升阳，*李云潼*，阮利. 面向云边端协同环境的数据布局方法[P]. 中国专利: CN119544721A, 2025-02-28.

    == 攻读硕士学位期间参与的主要科研工作

    #set par(
      justify: true,
      first-line-indent: 2em,
      hanging-indent: 0em,
    )

    参与国家重点研发计划共性关键技术类专项“面向云边端协同的芯粒结构与系统软件”（项目编号：2023YFB4503100，周期：2023.11–2026.10）。作为项目/课题骨干，全面参与了项目的调研、申报及实施工作。期间，围绕云边端跨域分布式训练场景下的通信瓶颈问题开展系统性研究，主要负责通信优化技术方案的设计、实现及相关实验验证。
  ],
  acknowledgements: [
    时光荏苒，从我收到北航录取通知书的那刻起，至今已过了三年。回首这一段时光，我深感自己无论是学术探索亦或是个人成长方面都取得了显著的进步，这都得益于在这段时光中遇到的每一个人给予我的帮助和鼓励。在此，我想向所有陪伴我走过这段旅程的人表达最诚挚的感谢。

    首先，我由衷感谢我的导师肖利民教授。肖老师深厚的学术造诣、独到的见解和严谨的治学态度，深深地感染了我。对于每个科研项目，大到整体架构设计，小到每个技术细节，肖老师都亲力亲为，与我们展开深入的细致探讨，力求完美，使我们能够高质量地完成科研工作。非常感谢肖老师对我在科研道路上的指导，让我得到了成长。同时，也要感谢课题组的王良老师、霍志胜老师、阮利老师、刘磊、廖晓坚老师。各位老师尽职尽责地完成了实验室的组织管理工作，同时为我们的学术研究提供了充足的指导性意见。

    其次，我要感谢实验室的同学们对我的关心和帮助。非常感谢王锦权博士对我在科研工作和工程实践上的指导和讨论，锦权学术能力比起我都要强上不少，让我十分钦佩。在和锦权一同完成的各项科研工作中，我们相互之间的讨论和分析给我提供了许多帮助，教会了我许多工程技术上的学习技巧，也获取了很多学术上的灵感。同时也要感谢我的同门谭升阳同学，和他在研究生伊始共同求学时便是我学习的榜样，他的代码能力和工程经验在我的开发过程和求职过程中给予了很大帮助。同样也要感谢贾志斌师兄和沈润楠师兄，两位师兄为我的学术探索提供了宝贵的思路。感谢各位同窗好友们，与你们共度的时光充满欢乐和收获。

    此外，我要特别感谢我的家人。感谢我的父母对我的关心和支持，让我能够心无旁骛地完成学业。在我求学的道路上，你们始终是我最坚实的后盾。

    最后，我要感谢参与本论文评审和答辩的各位专家教授，各位的宝贵意见对我论文质量的提高起到了至关重要的作用。我将认真对待每一条建议，不断完善自己的学术成果。

    再次向所有给予我帮助的人致以最诚挚的谢意！
  ],
  conclusion: [
    == 论文工作总结
    本论文面向云边端跨域分布式训练中的通信数据规模大，通信链路间异构，训练尾部同步延迟高等挑战，开展面向云边端跨域分布式训练的低比特优化器量化方法、基于流水线的层次化通信调度策略、混合并行通信掩盖策略等系统性研究，优化跨域训练通信中的三个关键环节（数据规模大小、通信算法优劣、计算通信掩盖程度）提出了一套高效的跨域协同训练通信优化方案，提升云边端跨域分布式训练效率。本文的主要工作和成果总结如下：

    （1）针对跨域受限链路下数据交换载荷过大导致的训练吞吐受限问题，提出一种分布式优化器低比特量化方法。首先，通过 k-bit 随机舍入量化分布式压缩机制，将连续浮点梯度映射为低比特表示的有限的离散数值；其次，通过带有残差补偿的量化同步与低位聚合算法，以缓解位宽降低带来的累积噪声，并优化了单次同步的通信带宽开销。实验证明，该方案在低带宽场景下显著降低了梯度通信同步开销，且加速优势随网络受限程度逐渐增强。基于随机舍入量化，该方案在受限网络下可大幅压缩梯度通信量，并可保障收敛稳定性；通过低位宽全归约方法，该方案克服了低位宽数据和高效集合通信方法不兼容的问题。

    （2）针对跨域链路中跨域链路异构且域间网络带宽低导致的训练中集合通信执行效率低的问题，提出一种基于流水线的层次化梯度通信调度策略。首先，通过引入分层集合通信算法，将全局各节点的全归约通信分解为域内归约、跨域传输与域内广播三个阶段，降低了域间通信量；其次，通过引入张量分块级的流水线机制，将域内规约、跨域传输与域内广播三阶段按切分的张量块流水执行，优化了跨域链路间通信时域内链路的利用率。实验证明，该方案优化了跨域异构集群间数据聚合的调度重叠率，充分利用了域内部的高速带宽。通过引入分层集合通信算法，降低了原始集合通信在云边端跨域场景下在域间的通信时间，大幅消除了通信启动延迟。通过引入张量块流水执行，并行了域间和域内通信，降低了原始分层集合通信算法的整体开销。

    （3）针对跨域训练在单次迭代末尾极易产生不可掩盖的阻塞式同步尾延迟问题，提出一种面向通信受限场景下的混合并行通信掩盖策略。首先，通过在反向传播阶段提前触发非阻塞集合通信，为梯度同步的长尾部预留足够的计算掩盖窗口；其次，利用张量缩放策略，来预测推算尚未计算完成的梯度数据并将其纳入跨域梯度同步，降低由于提前触发通信导致的梯度数据尺度不一致的问题；最后，利用轻量级误差反馈，将预测梯度值与剩余梯度的偏差延迟补偿至下一计算迭代，去除了由于使用仅部分数据的梯度信息产生的信息损失。实验证明，该方案优化了设备本地计算时间与跨域通信时长的掩盖比率，最终成功消除了由跨域 All-Reduce 造成的尾部纯等待空窗，且维持了每迭代一次全局同步的语义。

    == 下一步工作展望

    本文解决了在云边端跨域分布式训练通信优化中的三类关键问题，优化了跨域训练通信效率，提升了跨域训练的整体性能。但这些方法仍具有一定的改进空间，其中主要包含以下三方面：

    （1）在低比特优化器量化方法中，本文采用了基于块量化的随机舍入量化策略和量化误差补偿技术来保证训练精度，但是在实际应用中，针对不同模型结构、训练任务和数据分布，单一的量化策略并不总是最优解。固定的块大小可能无法始终保持着最优精度解，依据如下。对于不同的模型结构、训练任务和数据分布，梯度数值的分布和异常值频率很有可能不一样。对较大的异常值频率而言，较小的块大小可能更有利于捕捉异常值，从而保持训练精度，但提升了传输的数据量；而对于较小的异常值频率而言，较大的块大小可能更有利于提高压缩率，但提升了当某块出现异常值时对该块总体量化数值影响的规模。因此，未来的工作可以考虑引入动态块量化方法，根据模型结构、训练任务和数据分布的不同，动态调整块大小，得到一个最优块粒度取值。提升训练精度的同时，以进一步提升量化优化器的性能。其次，本文的低比特全归约方法还可进一步提升效率，通过重写NCCL All-Reduce Kernel，将All-to-all和本地反量化规约操作融合，实现通算融合。由于All-to-all通信的特点是每个节点都会依次收到来自其他节点的部分数据，因此在接收数据的同时就可以进行反量化规约操作，避免了先完成All-to-all通信再进行反量化规约的两阶段过程，从而进一步提升通信效率。

    （2）在基于流水线的层次化通信调度策略中，本文提出了基于张量切分的流水线机制和双流并行执行来提升跨域链路的利用率，但在实际应用中，训练节点间的通信拓扑结构可能更加复杂，正像本文所述，不同的链路结构需要不同的通信算法来达成最好的性能表现。仅仅将云边端链路解构为域内和域间来分析，没有结合更细粒度的拓扑感知是这一方法的缺点。因此，未来的工作可以考虑引入更细粒度的拓扑感知机制，来适应更复杂的通信拓扑结构。通过对训练节点间的通信拓扑进行更细粒度的分析和建模，识别出不同链路之间的性能差异和瓶颈，进行通信算法的微调。从而设计出更加适应实际通信拓扑结构的调度策略。提升跨域链路的利用率，进一步提升跨域训练的整体性能。

    （3）在混合并行通信掩盖策略中，本文提出了在每步一次全局同步的语义下，将 All-Reduce 触发点前移并引入预测误差修正来消减迭代尾部的等待。在实际应用中，大型模型的训练实现范式已经偏向于 Megatron、DeepSpeed 的整体架构，但我们的工作仅支持在 PyTorch 上进行训练，没有兼容更多的并行策略，例如张量并行、序列并行和上下文并行等。因此，未来的工作主要考虑将我们的方法适配进入 Megatron，从而支持各类大模型训练的并行策略，将本方法在业界真正落地，在更大规模的模型训练中验证其有效性，并扩展至真实预训练任务中验证其有效性。
  ]
  // cv: [
  //   2023年09月 - 2026年06月：北京航空航天大学，计算机科学与技术专业，硕士研究生

  //   2019年09月 - 2023年06月：北京交通大学，计算机科学与技术专业，工学学士
  // ],
)

// Chapter imports (split into per-chapter files)
// Keep the front-matter and import chapters in order

#include "src/chapters/ch1-intro.typ"
#include "src/chapters/ch2-background.typ"
#include "src/chapters/ch3-quantization.typ"
#include "src/chapters/ch4-scheduling.typ"
#include "src/chapters/ch5-overlap.typ"
#include "src/chapters/ch6-system-integration.typ"

// = 总结与展望
