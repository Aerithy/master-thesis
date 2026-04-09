#import "template/lib.typ": thesis
#import "template/src/abstract.typ": abstract, abstract-en

#let abstract-zh-text = [
  #show: abstract.with(keyword: ("分布式训练", "云边端协同", "跨域通信", "通信优化", "大语言模型"))

  在大语言模型训练中，分布式训练技术已成为支撑大规模模型训练的核心基础。随着训练数据与算力资源从“单一数据中心”走向“云-边-端协同”的跨域形态——数据分布在云端数据湖、边缘微型数据中心与端侧设备，算力分散在中心云 GPU 集群、边缘 GPU/CPU 节点与部分端侧加速器——训练系统面临更强的异构性：域内链路（如同机 NVLink/PCIe、同域 RDMA）高带宽低时延，而跨域链路（边缘到云、边缘到边缘、端到边缘的蜂窝/宽带接入）往往带宽更低、RTT 更高且抖动更大。由此产生的梯度同步通信开销更容易进入迭代关键路径，成为制约云边端协同训练吞吐与时延的关键瓶颈。

  针对上述挑战，本文以“跨域（Cloud–Edge–Device）分布式训练通信优化”为目标，从通信量、集合通信调度、计算-通信重叠三个层面开展系统性研究。本文主要工作如下：

  （1）通信数据量优化：提出 k-bit 随机舍入量化分布式优化方法，支持 $b in {1, 2, 4, 8, 16}$ 的可配置位宽。在受限链路条件下，通信数据量最高可降低至原有的 1/32，并可在压缩率与收敛稳定性之间进行可调折中；同时设计与之配套的量化同步与聚合机制，实现对低比特量化张量的高效通信支持。

  （2）集合通信调度优化：系统分析跨数据中心场景下的 All-Reduce 通信过程，针对 NCCL 的 CollNet 通信机制进行改进，提出多层流水线通信调度策略，充分利用集群间和集群内的异构带宽资源，显著加速通信过程。

  （3）计算-通信重叠优化：量化分析混合并行策略下的计算-通信重叠程度，对比跨数据中心通信与数据中心内部通信的重叠差异，通过重新设计混合并行模式下的梯度同步机制，有效提升计算-通信掩盖程度。
]

#let abstract-en-text = [
  #show: abstract-en.with(keyword: ("Distributed Training", "Cloud-Edge-Device Collaboration", "Cross-Domain Communication", "Communication Optimization", "Large Language Models"))

  Distributed training has become the fundamental infrastructure for large language model training. As training data and compute resources evolve from a single data center to cloud-edge-device collaboration—where data resides across central clouds, edge micro-data centers, and end devices, and compute spans cloud GPU clusters and heterogeneous edge nodes—training systems face stronger cross-domain heterogeneity: intra-domain links (e.g., NVLink/PCIe, RDMA) are high-bandwidth and low-latency, while cross-domain links (edge-to-cloud, edge-to-edge, and device-to-edge access networks) are typically bandwidth-limited with higher RTT and larger jitter. As a result, gradient synchronization is more likely to fall onto the critical path and become a key bottleneck for end-to-end throughput and latency.

  To address these challenges, this thesis targets communication optimization for cross-domain (Cloud–Edge–Device) distributed training. Cross-data-center training is treated as a representative, strongly-constrained instance of cloud-edge / edge-edge interconnects, capturing the key characteristics of low bandwidth and high RTT. The main contributions are as follows:

  (1) *Communication Volume Optimization*: We propose a k-bit stochastic-rounding distributed optimization method with configurable bit widths ($b in {1, 2, 4, 8, 16}$). Under constrained links, it reduces communication volume by up to 32x (1/32 of the original size) while enabling a tunable trade-off between compression ratio and convergence stability; we further design a compatible quantized synchronization and aggregation mechanism to efficiently support low-bit quantized tensors.

  (2) *Collective Communication Scheduling Optimization*: We systematically analyze the All-Reduce communication process in cross-data-center scenarios, improve upon NCCL's CollNet communication mechanism, and propose a multi-level pipeline communication scheduling strategy that fully exploits heterogeneous bandwidth resources between and within clusters, significantly accelerating the communication process.

  (3) *Computation-Communication Overlap Optimization*: We quantitatively analyze the degree of computation-communication overlap in hybrid parallelism strategies, compare the overlap differences between cross-data-center communication and intra-data-center communication, and improve the overlap degree by redesigning the gradient synchronization mechanism in hybrid parallelism mode.
]

#show: thesis.with(
  title: (zh: "面向云边端协同的跨域分布式训练通信优化研究", en: "Research on Communication Optimization for Distributed Training in Cross-Domain Multi-Data Center Scenarios"),
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
    围绕云边端跨域分布式训练通信优化开展系统研究，形成了本文提出的关键方法与实验结果。

    完成了相关实验平台搭建、算法实现与论文撰写工作。
  ],
  acknowledgements: [
    衷心感谢导师肖利民教授在选题、研究思路与论文写作过程中给予的悉心指导。

    感谢课题组老师和同学在研究讨论、实验环境支持与论文修改方面提供的帮助。

    感谢家人和朋友在学习与科研期间给予的理解、关心与支持。
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



