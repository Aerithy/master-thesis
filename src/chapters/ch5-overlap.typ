#import "../../template/src/algorithm.typ": pseudocode-list
#import "../../template/src/constant.typ": font-type

= 通信受限场景下的混合并行通信掩盖策略

== 研究背景与动机

跨数据中心（Cross-DC）训练常见于数据就地合规、跨地域数据融合与算力资源分散等场景。与单数据中心互联（如 InfiniBand/RDMA）相比，广域网（WAN）通常只有 10–30 Gb/s 量级带宽、30–100 ms 往返时延（RTT），使得同步训练中的通信开销直接进入关键路径，造成 GPU 长时间空闲与吞吐下降。

从云边端协同训练的视角，Cross-DC 可视为“边缘域↔云域（或边缘域↔边缘域）”跨域互联的一种典型抽象：边缘侧承载就近计算与数据处理，云侧提供集中化算力与全局一致性；当训练以跨域数据并行（DP）为骨架时，梯度均值 All-Reduce 必须跨越边缘到云的 WAN 链路，从而形成显著的同步尾部。端侧设备虽然未必直接参与大规模 All-Reduce，但它们持续将数据/梯度贡献汇入边缘域，使得边缘域成为跨域同步的“入口”，进一步放大 WAN 抖动对全局吞吐的影响。

从系统角度看，Cross-DC 训练的难点不只在于“带宽更低”，还在于“时延更高且更难被隐藏”。当 RTT 达到毫秒量级时，许多传统在单数据中心可忽略的等待（例如一次 collective 的启动、同步点的排队）都会叠加成显著的迭代尾部。与此同时，跨 DC 的网络抖动还会放大 *同步屏障* 对全局吞吐的影响：任何一个 DC 的短暂变慢，都可能让所有 GPU 在屏障处空等。

=== 并行骨架的选择：跨 DC DP 优于跨 DC PP

在 Cross-DC 环境中，以流水线并行为骨架（跨 DC PP）会迫使训练样本/激活在数据中心之间频繁穿梭，入口与跨段链路容易成为瓶颈，如图@fig:cross-dc-pp 所示。

#figure(
  image("../../supplementary/images/pp_across_dcs.png", width: 96%),
  caption: [跨数据中心流水线并行：数据必须汇入单入口 DC，产生入口瓶颈（复用自论文 Fig.1）]
) <fig:cross-dc-pp>

相对地，以数据并行为骨架（跨 DC DP）将前/后向计算限定在数据中心内，仅在迭代末进行梯度同步，天然契合数据就地处理，并对网络波动更鲁棒，如图@fig:cross-dc-dp 所示。

#figure(
  image("../../supplementary/images/dp_across_dcs.png", width: 96%),
  caption: [跨数据中心数据并行 + 数据中心内流水线并行：各 DC 处理本地数据，仅跨 WAN 同步梯度（复用自论文 Fig.2）]
) <fig:cross-dc-dp>

因此，本章聚焦论文设定的层次化混合并行：跨 DC 采用 DP，同一数据中心内采用 PP（DP+PP）。该设定避免跨 DC 传输激活/样本，但引入新的关键瓶颈：跨 DC 梯度同步尾部（All-Reduce tail）。

为进一步说明“跨 DC DP 优于跨 DC PP”的结构性原因，可以用通信量随 batch 规模的增长趋势来刻画。设共有 $D$ 个数据中心，每个 DC 处理本地 batch $b$，则全局 batch 为 $B = D dot b$。令 $alpha$ 表示每个参数参与同步的字节数（与精度/压缩有关），$P$ 表示模型参数规模（以参数个数或字节计），$A$ 表示当流水线切分跨越数据中心时每个样本需要跨 WAN 传输的激活（及其反向激活梯度）大小。

当跨 DC 采用 DP 时，跨 WAN 的通信主要来自每步一次的梯度同步，其通信量近似与模型规模相关：

$ V_"DP" approx alpha dot P $

在模型固定时，$V_"DP"$ 随 $B$ 增加近似不变，从而更容易通过增大 batch 或提升 DC 内计算并行来摊薄 WAN 固定开销。

当跨 DC 采用 PP 时，一旦流水线切分跨 DC，则每个 micro-batch 都需要跨 WAN 传输激活，迭代内 WAN 流量与样本数近似线性增长：

$ V_"PP" approx Theta(B dot A) $

并且 PP 的跨 DC 传输更可能位于计算关键路径之上（stage 依赖强），一旦 WAN 出现波动，容易级联放大为全流水线停顿。因此，论文选择“跨 DC DP + DC 内 PP”的层次化骨架，以在数据就地的前提下，尽可能将 WAN 通信从强依赖链路中剥离。

=== 同步尾部成为主要瓶颈

在 WAN 延迟主导时，即使框架在反向传播期间做了“分桶 All-Reduce”重叠，也容易出现迭代末尾无法被剩余计算掩盖的阻塞尾部。图@fig:dppp-timebreakdown 展示了 DP+PP 配置下跨 DC 与 DC 内开销分解：跨 DC 同步在每步中占据显著比例，导致 GPU 等待。

#figure(
  image("../../supplementary/images/bar_time_by_network.png", width: 96%),
  caption: [DP+PP 配置下每步计算/通信开销分解：跨 DC 同步成为主要等待来源（复用自论文 Fig.3）]
) <fig:dppp-timebreakdown>

面对同步尾部，一类直观做法是弱化同步（如 Local-SGD），但其本质是降低同步频率而非消除同步尾部，且会引入更强的优化漂移风险。本章采用论文提出的 POLAR-SGD：在不改变“每迭代一次全局同步”这一基本语义的前提下，通过 *前缀触发的异步 All-Reduce + 预测误差修正* 将同步从关键路径中剥离。

需要补充的是，单数据中心场景中常见的“bucket 级别通信重叠”（例如按参数桶在反向传播过程中分批启动 All-Reduce）在 WAN 环境下往往不足以完全隐藏同步开销。原因在于：WAN 的 $T_"ar"$ 可能显著大于单个 bucket 之后剩余的可用计算窗口，导致最后几个 bucket 的同步不可避免地串行堆叠在迭代尾部，形成长尾。POLAR-SGD 的思路并不是让 All-Reduce 发生得更“碎”，而是通过选择一个 *更早、更长* 的可重叠窗口（在 micro-batch 前缀处触发一次 collective），让整个 All-Reduce 更大概率被后续反向传播所掩盖。

== 问题设定与记号

考虑一个 DP+PP 混合训练过程：每个全局迭代（step）以一个 mini-batch 为单位，将其划分为 $M$ 个 micro-batch 并采用 1F1B 调度执行。跨 DC 使用 DP（DP 组大小为 $N$），同一 DC 内使用 PP（用于模型切分与计算流水线）。

在该设定下，DC 内 PP 负责把计算“铺开”以提升显存可承载的模型规模，并通过 1F1B 将多个 micro-batch 的前向/反向交错执行来提高单 DC 内的流水线利用率；跨 DC DP 则要求每步获得一致的更新方向，需要对 DP 组内的梯度做均值 All-Reduce。该 All-Reduce 因 WAN 特性成为尾部瓶颈。

在一个迭代 $t$ 内、DP 组内的 worker（rank）$r$ 上，micro-batch $m$ 的局部梯度记为 $g_(r,t,m)$。我们关心如何选择一个 micro-batch 截断点 $tau$，在 $m=tau$ 时启动一次非阻塞 All-Reduce，并利用误差反馈在后续迭代补齐未同步的梯度信息。

#figure(
  table(
    columns: (auto, auto),
    align: left,
    stroke: none,
    table.hline(),
    table.header([*符号*], [*含义*]),
    table.hline(stroke: 0.5pt),
    [$M$], [每个 mini-batch 的 micro-batch 数],
    [$m$], [micro-batch 索引],
    [$t$], [全局迭代索引],
    [$r$], [DP 组内 worker（rank）索引],
    [$g_(r,t,m)$], [worker $r$ 在迭代 $t$、micro-batch $m$ 的梯度],
    [$g_(r,t)^(tau)$], [前缀累积梯度：从 $m=1$ 到 $m=tau$ 的累积],
    [$g_(r,t)^(M)$], [完整累积梯度：从 $m=1$ 到 $m=M$ 的累积],
    [$g_"pred",(r,t)$], [截断点处构造、送入 All-Reduce 的预测梯度（缩放后）],
    [$g_"sync",t$], [All-Reduce 的同步梯度（DP 组内均值）],
    [$e_(r,t)$], [误差缓冲（error buffer）],
    [$s_(r,t)$], [通信发送缓冲（send buffer）],
    [$h_t$], [异步通信句柄（handle）],
    [$w_t$], [迭代 $t$ 的模型参数],
    [$eta$], [学习率],
    [$tau$], [通信触发的截断 micro-batch 索引],
    table.hline(),
  ),
  caption: [POLAR-SGD 记号表（整理自论文 Notation 表）]
) <tab:polar-notation>

== POLAR-SGD：方法概述

图@fig:polar-overview 对比了标准 DP+PP 与 POLAR-SGD 的单次迭代时间线。标准做法往往在处理完全部 $M$ 个 micro-batch 的反向传播后，才在迭代尾部执行阻塞式 All-Reduce，形成明显同步尾部；POLAR-SGD 则在 micro-batch 前缀完成时（$m=tau$）触发 *一次* 非阻塞 All-Reduce，并放入独立通信 stream，使其与后续 $(M-tau)$ 个 micro-batch 的反向传播重叠，从而缩短迭代尾部。

#figure(
  image("../../supplementary/images/polar-pp-timeline.png", width: 98%),
  caption: [DP+PP 下的执行时间线对比：POLAR-SGD 通过前缀触发的异步 All-Reduce 缩短同步尾部（复用自论文 Fig.4）]
) <fig:polar-overview>

需要强调的是：POLAR-SGD 并非简单丢弃后缀 micro-batch 的梯度，而是通过 *梯度缩放 + 误差反馈* 的方式将后缀信息以残差形式注入到下一次迭代，兼顾“可重叠的系统行为”与“稳定的优化语义”。

为了便于理解，可以将 POLAR-SGD 的目标概括为三点：

1. *系统目标*：尽可能将跨 DC All-Reduce 放到足够早的位置，使其能与后续计算重叠，从而缩短迭代尾部。

2. *语义约束*：仍保持“每迭代一次 DP 同步”的宏观节奏，避免完全异步带来的强 staleness。

3. *优化稳定性*：用可控的残差通道补齐后缀梯度，使 step-wise 的收敛曲线尽量贴近基线同步训练。

== 前缀触发的异步梯度同步

=== 一次迭代只触发一次 All-Reduce

POLAR-SGD 在每个 micro-batch 反向结束时累积梯度。当到达截断点 $m=tau$ 时，对当前前缀梯度做快照并构造发送缓冲 $s_(r,t)$，随后触发一次非阻塞 All-Reduce；在 $m=M$（mini-batch 结束）时等待通信完成，得到 $g_"sync",t$ 并执行优化器更新。

这里“每迭代一次 All-Reduce”的设计有两个直接好处：

1) *避免频繁 collective 的启动开销*：在 WAN 环境下，collective 的启动与同步管理开销更难忽略，过细粒度可能适得其反。

2) *便于与 DP+PP 的控制流集成*：在 1F1B 调度下，micro-batch 的反向完成顺序明确，选择一个截断点能稳定地产生较长的可重叠窗口。

#figure(
  kind: "algorithm",
  placement: top,

  pseudocode-list(booktabs: true, numbered-title: [算法 1：POLAR-SGD 的前缀触发异步 All-Reduce（每迭代一次）], full: true)[
    - *全局状态：* 累积梯度 $g_a$；前缀快照 $g^(tau)$；通信句柄 $h_t$
    - *回调：* 在每个 micro-batch 反向结束时调用

    + $g_a <- g_a + g_(r,t,m)$ #h(1em) ▷ PP 的梯度累积
    + *if* $m = tau$ *then*
      + $g^(tau) <- g_a$ #h(1em) ▷ 记录前缀梯度快照
      + $s_(r,t) <- "BuildSendBufferAtCutoff"(t, g^(tau))$
      + $h_t <- "AsyncAllReduceMean"(s_(r,t))$
    + *end*
    + *if* $m = M$ *then*
      + *wait* $(h_t)$ #h(1em) ▷ 得到同步梯度 $g_"sync",t$
      + $"OptimizerStep"(g_"sync",t)$
      + $"UpdateError"(t, g_a)$ #h(1em) ▷ 用完整累积梯度更新误差缓冲
      + $g_a <- 0$; $h_t <- "NULL"$
    + *end*
  ],
) <algo:polar-communication>

=== 截断点 $tau$ 的选择规则

令 $T_"ar"$ 表示本次梯度 All-Reduce 的平均通信时延估计，$T_"comp"(tau)$ 表示在 $m=tau$ 触发通信后，迭代内剩余的计算时间（通常来自后续 micro-batch 的反向传播）。论文采用“*最早可完全掩盖*”的截断点：

$ tau^* := min {tau in {1, ..., M}: T_"comp"(tau) >= T_"ar"} $

实践中，可通过滑动窗口在线 profiling 获得 $T_"ar"$ 与 $T_"comp"(tau)$ 的估计：较小 $tau$ 带来更长的可重叠窗口，但也会加大对误差反馈的依赖；较大 $tau$ 则更接近基线的同步语义。

当对所有 $tau$ 都无法满足 $T_"comp"(tau) >= T_"ar"$ 时，可以退化为 $tau^* = M$，此时算法行为接近“迭代末同步”的基线。该退化机制使得 POLAR-SGD 能在网络条件较好或模型计算较短等情形下自动回到保守策略。

在工程实现上，$T_"ar"$ 可由最近若干步 All-Reduce 的完成时延统计得到；$T_"comp"(tau)$ 则可由 profiler 记录从 micro-batch $tau$ 反向完成到本迭代结束（$m=M$）的剩余反向时间估计。为了避免 $tau$ 在相邻迭代间剧烈抖动，通常会对估计值做滑动平均，并在更新 $tau$ 时加入简单的迟滞（例如只有当新 $tau$ 带来显著收益时才切换）。

== 预测误差修正（Predictive Error Correction）

前缀触发意味着本次迭代的同步更新方向来自前缀梯度。为避免“后缀 micro-batch 信息被忽略”，POLAR-SGD 通过“前缀缩放”构造全 batch 尺度的预测梯度，并维护误差缓冲记录预测与真实完整累积之间的偏差。

=== 前缀梯度与完整梯度

在 worker $r$ 的迭代 $t$ 中，定义：

$ g_(r,t)^(tau) := sum_(m=1)^tau g_(r,t,m),  quad g_(r,t)^(M) := sum_(m=1)^M g_(r,t,m) $

当 $m=tau$ 时，累积缓冲 $g_a$ 等于 $g_(r,t)^(tau)$；当 $m=M$ 时，$g_a$ 等于 $g_(r,t)^(M)$。

=== 发送缓冲与误差更新

在截断点处构造发送缓冲（同时作为预测梯度的未归约形式）：

$ s_(r,t) = (M/tau) dot (g_(r,t)^(tau) + e_(r,t)),  quad g_"pred",(r,t) := s_(r,t) $

对 $s_(r,t)$ 做 DP 组内均值 All-Reduce，得到同步梯度：

$ g_"sync",t = (1/N) sum_(r=1)^N g_"pred",(r,t) $

当迭代内全部 $M$ 个 micro-batch 完成后，用“完整累积梯度 − 预测梯度”更新误差缓冲：

$ e_(r,t+1) = g_(r,t)^(M) - g_"pred",(r,t) $

该残差包含后缀 $(M-tau)$ 个 micro-batch 的梯度信息以及前缀预测误差，并在下一迭代通过 $e_(r,t)$ 注入到发送缓冲中，从而以受控方式“延迟使用”后缀梯度。

从直观上看，$(M/tau)$ 的缩放因子承担了“把前缀的梯度尺度外推到全 batch”的作用：如果梯度在 micro-batch 维度上统计上相对平稳，那么 $g_(r,t)^(tau)$ 的期望规模与 $tau$ 成正比，乘以 $(M/tau)$ 后就与 $g_(r,t)^(M)$ 更接近。误差缓冲 $e_(r,t)$ 则用于吸收“外推偏差 + 后缀梯度信息”，把这些信息以 residual 的形式带到下一步同步中。

论文还给出了一个有用的“守恒”视角：对 DP 组内取平均，令 $bar g_t^(M) := (1/N) sum_(r=1)^N g_(r,t)^(M)$ 且 $bar e_t := (1/N) sum_(r=1)^N e_(r,t)$，则在误差更新定义下可得到（形式上）

$ g_"sync",t + bar e_(t+1) = bar g_t^(M) $

该等式说明：同步更新方向与下一步的平均残差共同分解了“本步完整累积梯度”的信息；也就是说，后缀 micro-batch 的信息并未被忽略，只是被延迟到 residual 通道中体现。

#figure(
  kind: "algorithm",
  placement: top,

  pseudocode-list(booktabs: true, numbered-title: [算法 2：POLAR-SGD 的误差反馈（前缀缩放 + residual 更新）], full: true)[
    - *全局状态：* 误差缓冲 $e_(r,t)$；预测梯度 $g_"pred",(r,t)$；$tau$ 与 $M$

    + *procedure* $"BuildSendBufferAtCutoff"(t, g_(r,t)^(tau))$
      + $s_(r,t) <- (M/tau) dot (g_(r,t)^(tau) + e_(r,t))$
      + $g_"pred",(r,t) <- s_(r,t)$
      + *return* $s_(r,t)$
    + \
    + *procedure* $"UpdateError"(t, g_(r,t)^(M))$
      + $e_(r,t+1) <- g_(r,t)^(M) - g_"pred",(r,t)$
  ],
) <algo:polar-error-feedback>

== 工程实现与系统集成（扩写）

虽然本章重点在算法机制，但要在真实的 DP+PP 系统中获得稳定收益，还需要在控制流与执行资源（CUDA stream）层面保证“异步通信确实与计算并行”。结合论文设定，这里给出更贴近工程实现的集成要点。

=== 与 1F1B 流水线的集成位置

在 1F1B 调度中，micro-batch 的反向传播会按固定节奏在各 stage 上完成。POLAR-SGD 的关键是：在每个 DP rank 上，在 *某个 micro-batch 的反向结束时刻* 统一触发一次 All-Reduce。实现时通常会在“梯度累积完成事件”处设置 hook（或在训练循环里显式判断 $m=tau$），以便在该时刻将 $s_(r,t)$ 交给通信后端。

由于各 stage 的反向完成存在相位差，实际系统中更常见的做法是：在每个 DP rank 内先对所有参数做一次“完整梯度张量”的累积（或以 bucket 形式累积），然后在 $m=tau$ 时对该累积缓冲做快照并进入 All-Reduce。这样能避免在每层/每 bucket 上重复触发通信，符合“每迭代一次 collective”的设计初衷。

=== 通信 stream 与计算 stream 的隔离

要实现重叠，All-Reduce 必须在独立的通信 stream 上启动，且计算 stream 不应等待其完成。一个常见实现骨架是：

1. 计算 stream 完成 micro-batch $m=tau$ 的反向后，记录一个 event。

2. 通信 stream 等待该 event（确保 $s_(r,t)$ 写入完成），随后启动异步 All-Reduce（例如 NCCL 的 async_op）。

3. 计算 stream 继续执行后续 micro-batch 的反向传播与梯度累积。

4. 在 $m=M$ 的更新点，计算 stream 才显式 wait 通信句柄，获取 $g_"sync",t$。

该隔离可以避免“通信被默认 stream 的同步语义拖回关键路径”。

=== 误差缓冲的存储与开销

$e_(r,t)$ 与模型梯度同形，最直接的实现是在每个 DP rank 上维护一个与梯度张量同大小的 buffer。其更新发生在 $m=M$ 之后：此时已得到完整累积梯度 $g_(r,t)^(M)$，且预测梯度 $g_"pred",(r,t)$ 在 $m=tau$ 时已记录。更新 $e_(r,t+1)$ 是一次向量差，额外开销相对一次完整反向传播通常较小，但会带来一定显存占用；因此工程上常结合张量扁平化/分桶来减少 buffer 管理复杂度。

== 理论分析：收敛与稳定性（概要）

在标准随机优化假设下（$L$-光滑、随机梯度无偏、方差有界），论文给出 POLAR-SGD 的收敛性分析：其渐近收敛行为与同步 SGD 一致，且仅额外引入一个由误差缓冲控制的项。

设 $bar e_t := (1/N) sum_(r=1)^N e_(r,t)$，当学习率满足 $eta <= 1/(2L)$ 时，经过 $T$ 次全局迭代，有：

$ (1/T) sum_(t=0)^(T-1) bb(E)[||nabla f(w_t)||^2] <= (2 (f(w_0)-f^*))/(eta T) + (L eta sigma^2)/N + (L eta)/T sum_(t=0)^(T-1) bb(E)[||bar e_t||^2] $

该上界表明：当按 $tau$ 选择规则使得通信尽量被掩盖、并使误差缓冲保持有界时，POLAR-SGD 的优化稳定性可以与基线同步训练保持接近。

从解释角度看，该界由三部分组成：

1) $O(1/T)$ 的优化项：随着迭代步数增长而下降；

2) $sigma^2/N$ 的方差缩减项：与标准 DP 的均值 All-Reduce 一致，体现“更多 DP rank 降低随机梯度方差”；

3) 与 $||bar e_t||^2$ 相关的误差项：体现前缀触发带来的近似偏差由 error feedback 控制。

因此，$tau$ 的选择在理论与实践中都扮演折中角色：更早触发（更小 $tau$）带来更强的重叠潜力，但也可能使 $||bar e_t||$ 更大；更晚触发则降低误差项，但可能无法完全掩盖通信。

== 实验评估

=== 实验设置

论文在 Cross-DC 约束下评估 POLAR-SGD，并与标准 DP+PP 基线（DDP+1F1B，迭代末阻塞 All-Reduce）以及放松同步的 LSGD（$k=4$）对比。实验配置如下。

从云边端协同角度看，该实验设置对应“跨域 DP（跨云-边）+ 域内 PP（边缘域内流水线）”的层次化训练骨架：WAN 的带宽与 RTT 约束刻画边缘↔云（或边缘↔边缘）链路特性，而域内互联与多卡节点刻画边缘域内部的高带宽计算集群。因而，本章实验可用于验证在云边端协同场景中，如何通过更早触发、可重叠的异步 All-Reduce 来降低跨域同步尾部。

#figure(
  table(
    columns: (auto, auto),
    align: left,
    stroke: none,
    table.hline(),
    table.header([*组件*], [*配置*]),
    table.hline(stroke: 0.5pt),
    [Model], [LLaMA-2 7B],
    [Dataset], [WikiText-103],
    [Hardware], [32× NVIDIA A100 (40GB)，4 nodes],
    [Network], [Bandwidth: 30 Gb/s；RTT: 50 ms],
    [Parallelism], [Hybrid DP+PP（PP=8，DP=4）；batch=256；microbatch=32],
    [Software], [PyTorch 2.5；NCCL 2.23；CUDA 12.1],
    [Metrics], [吞吐（tokens/s），训练 loss],
    table.hline(),
  ),
  caption: [实验设置（整理自论文 Table: setup）]
) <tab:polar-setup>

=== 端到端吞吐

#figure(
  table(
    columns: (auto, auto, auto),
    align: center,
    stroke: none,
    table.hline(),
    table.header([*方法*], [*吞吐 (tokens/s)*], [*相对加速比*]),
    table.hline(stroke: 0.5pt),
    [DDP+1F1B], [5,350], [1.00×],
    [LSGD ($k=4$)], [9,433], [1.76×],
    [POLAR-SGD], [10,016], [1.87×],
    table.hline(),
  ),
  caption: [Cross-DC 约束下端到端吞吐（整理自论文 Table: throughput）]
) <tab:polar-throughput>

从吞吐对比可以看出：在 Cross-DC 约束下，基线 DDP+1F1B 的尾部同步显著拉长了单步时间；LSGD 通过减少同步强度/频率获得了较大吞吐提升，但其优化语义偏离基线更明显；POLAR-SGD 在保持“每步一次同步”的节奏下仍获得最高吞吐，说明“把同步从尾部挪到可重叠窗口”比“单纯减少同步”更契合 DP+PP 的系统结构。

=== 收敛曲线与消融

论文进一步给出了按 step 对齐的 loss 曲线（验证 step-wise 稳定性）、按 wall-clock time 对齐的 loss 曲线（验证 time-to-target 提升），以及对“梯度缩放 / 误差反馈”两项关键机制的消融结果。

#figure(
  image("../../supplementary/images/json_curves_by_steps.png", width: 92%),
  caption: [训练 loss 随 step 变化：POLAR-SGD 与基线高度一致，优于 LSGD 的偏移（复用自论文 Fig.5）]
) <fig:polar-loss-steps>

按 step 对齐的结果用于回答“算法是否改变了每一步的优化行为”：如果曲线与基线接近，说明误差反馈确实在统计意义上补偿了前缀触发带来的偏差，使得训练轨迹没有明显漂移。

#figure(
  image("../../supplementary/images/json_curves_by_time.png", width: 92%),
  caption: [训练 loss 随 wall-clock time 变化：POLAR-SGD 更快进入低 loss 区间（复用自论文 Fig.6）]
) <fig:polar-loss-time>

按 wall-clock time 对齐则更直接反映系统收益：即便 step-wise 曲线接近，只要单步时间被缩短，模型就能更快达到同等 loss 区间，从而提升 time-to-target。

#figure(
  image("../../supplementary/images/json_curves_by_steps_ablation.png", width: 92%),
  caption: [消融实验：去除梯度缩放或误差反馈会带来轻微收敛退化或稳定性风险（复用自论文 Fig.7）]
) <fig:polar-ablation>

消融结果强调了两个机制的必要性：

1) *梯度缩放*：若不做 $(M/tau)$ 缩放，则送入同步的梯度尺度偏小，容易导致更新量不足并拉慢收敛。

2) *误差反馈*：若不维护 residual，则后缀 micro-batch 的信息无法以可控形式回流到后续迭代，可能出现收敛退化或稳定性风险。

== 本章小结

本章围绕 Cross-DC 的 DP+PP 训练瓶颈（同步尾部）总结并对齐了 POLAR-SGD 的核心设计：

1. 采用跨 DC DP、DC 内 PP 的层次化并行，避免跨 DC 激活/数据搬运，但同步尾部成为关键瓶颈。

2. 在每迭代只触发一次 All-Reduce 的前提下，通过选择截断点 $tau$，将 All-Reduce 放入独立通信 stream 并与后续反向传播重叠，缩短迭代尾部。

3. 通过前缀缩放与误差反馈，将后缀 micro-batch 的梯度信息以残差形式注入下一迭代，兼顾系统效率与优化稳定性；论文实验在 30 Gb/s、50 ms RTT 的 Cross-DC 约束下实现 1.87× 吞吐提升，并保持与基线接近的 step-wise 收敛。

从全文视角看，本文提出的通信优化系统可归纳为“场景约束—并行骨干—协同优化”三层闭环：在云边端跨域训练中，系统首先面对“域内快、域间慢”的异构网络与跨域数据/算力分布这一基础约束；在此之上，采用跨域 `DP` 与域内 `DP/TP/PP` 结合的层次化并行骨干，以兼顾数据就地处理与大模型训练效率；最终在执行层将优化分解为低比特量化、分层集合通信流水化、计算-通信掩盖三个可组合模块，分别作用于通信量、通信路径与关键路径重叠。三者协同后形成端到端增益链路，使系统能够在保持训练语义稳定与工程可部署性的前提下，持续缓解跨域同步带来的吞吐下降与尾部阻塞。

#pagebreak()
