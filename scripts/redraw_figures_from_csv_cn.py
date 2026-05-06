from __future__ import annotations

from pathlib import Path

import matplotlib.font_manager as fm
import matplotlib.pyplot as plt
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
CSV_DIR = ROOT / "image" / "csv"
IMG_DIR = ROOT / "image"


def _try_register_simsun() -> None:
    # Try common SimSun locations; skip if not found.
    candidates = [
        Path("C:/Windows/Fonts/simsun.ttc"),
        Path("C:/Windows/Fonts/simsun.ttf"),
        ROOT / "assets" / "fonts" / "simsun.ttf",
        ROOT / "assets" / "fonts" / "simsun.ttc",
    ]
    for path in candidates:
        if path.exists():
            fm.fontManager.addfont(str(path))
            break


def _configure_plot_style() -> None:
    _try_register_simsun()
    # Convert text to paths in SVG to avoid font issues during Typst PDF export.
    plt.rcParams["svg.fonttype"] = "path"
    plt.rcParams["font.family"] = ["Times New Roman", "SimSun"]
    plt.rcParams["mathtext.fontset"] = "stix"
    plt.rcParams["axes.unicode_minus"] = False
    # Increase default typography by about 2 points for better readability.
    plt.rcParams["font.size"] = 12
    plt.rcParams["axes.titlesize"] = 14
    plt.rcParams["axes.labelsize"] = 12
    plt.rcParams["xtick.labelsize"] = 11
    plt.rcParams["ytick.labelsize"] = 11
    plt.rcParams["legend.fontsize"] = 10


def _save(fig: plt.Figure, filename: str) -> None:
    out = IMG_DIR / filename
    fig.tight_layout()
    fig.savefig(out, format="svg", dpi=300)
    plt.close(fig)
    print(f"generated: {out}")


def draw_ch3_comm_bottleneck() -> None:
    df = pd.read_csv(CSV_DIR / "ch3_comm_bottleneck.csv")

    fig, ax1 = plt.subplots(figsize=(9.4, 4.2))
    x = range(len(df))
    bars = ax1.bar(x, df["comm_per_iter_mib"], color=["#5B8FF9", "#61DDAA", "#F6BD16"], alpha=0.9)
    ax1.set_yscale("log")
    ax1.set_ylabel("每次迭代通信量（MiB，对数刻度）", fontsize=16)
    ax1.set_xticks(list(x))
    ax1.set_xticklabels(df["model"], rotation=0)
    ax1.set_title("不同模型规模的通信瓶颈", fontsize=18)
    ax1.grid(axis="y", linestyle="--", alpha=0.3)

    ax2 = ax1.twinx()
    ax2.plot(list(x), df["comm_share_percent"], color="#E8684A", marker="o", linewidth=2.2)
    ax2.set_ylabel("通信时间占比（%）", fontsize=16)
    ax2.set_ylim(0, 100)

    for b, val in zip(bars, df["comm_per_iter_mib"]):
        ax1.text(b.get_x() + b.get_width() / 2.0, val, f"{val:,.0f}", ha="center", va="bottom", fontsize=14)

    _save(fig, "ch3-comm-bottleneck.svg")


def draw_ch3_experiment_results() -> None:
    df = pd.read_csv(CSV_DIR / "ch3_experiment_results.csv")

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(11.2, 4.2))

    for col, label, color in [
        ("fp32_tokens_per_s", "FP32", "#8C8C8C"),
        ("k8_tokens_per_s", "8位", "#5B8FF9"),
        ("k4_tokens_per_s", "4位", "#61DDAA"),
        ("k2_tokens_per_s", "2位", "#F6BD16"),
        ("k1_tokens_per_s", "1位", "#E8684A"),
    ]:
        ax1.plot(df["bandwidth_mbps"], df[col], marker="o", linewidth=2, label=label, color=color)

    ax1.set_xscale("log")
    ax1.set_xlabel("跨域带宽（Mbps，对数刻度）", fontsize=16)
    ax1.set_ylabel("吞吐（tokens/s）", fontsize=16)
    ax1.set_title("带宽约束下的加速效果", fontsize=18)
    ax1.grid(True, linestyle="--", alpha=0.3)
    ax1.legend(frameon=False, fontsize=14)

    for col, label, color in [
        ("fp32_final_loss", "FP32", "#8C8C8C"),
        ("k8_final_loss", "8位", "#5B8FF9"),
        ("k4_final_loss", "4位", "#61DDAA"),
        ("k2_final_loss", "2位", "#F6BD16"),
        ("k1_final_loss", "1位", "#E8684A"),
    ]:
        ax2.plot(df["bandwidth_mbps"], df[col], marker="s", linewidth=2, label=label, color=color)

    ax2.set_xscale("log")
    ax2.set_xlabel("跨域带宽（Mbps，对数刻度）", fontsize=16)
    ax2.set_ylabel("最终验证损失", fontsize=16)
    ax2.set_title("量化位数对收敛稳定性的影响", fontsize=18)
    ax2.grid(True, linestyle="--", alpha=0.3)

    _save(fig, "ch3-experiment-results.svg")


def draw_ch3_method_comparison() -> None:
    df = pd.read_csv(CSV_DIR / "ch3_method_comparison.csv")

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(11.2, 4.2))

    colors = ["#8C8C8C", "#5B8FF9", "#F6BD16", "#E8684A", "#61DDAA"]

    throughput_col = "throughput_tokens_per_s" if "throughput_tokens_per_s" in df.columns else "throughput_metric"
    ax1.bar(df["method"], df[throughput_col], color=colors)
    ax1.set_ylabel("吞吐（tokens/s）", fontsize=16)
    ax1.set_title("不同方法的端到端吞吐", fontsize=18)
    ax1.grid(axis="y", linestyle="--", alpha=0.3)
    ax1.tick_params(axis="x", rotation=15)

    ax2.bar(df["method"], df["comm_share_percent"], color=colors, alpha=0.9, label="通信占比")
    ax2.plot(df["method"], df["p95_tail_ms"], color="#3D76DD", marker="o", linewidth=2.0, label="P95尾延迟（ms）")
    ax2.set_ylabel("通信占比（%）/尾延迟（ms）", fontsize=16)
    ax2.set_title("通信开销与尾延迟", fontsize=18)
    ax2.grid(axis="y", linestyle="--", alpha=0.3)
    ax2.tick_params(axis="x", rotation=15)
    ax2.legend(frameon=False, fontsize=14)

    _save(fig, "ch3-method-comparison.svg")


def draw_ch3_multimodel_e2e() -> None:
    df = pd.read_csv(CSV_DIR / "ch3_multimodel_e2e.csv")

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(11.2, 4.2))

    x = range(len(df))
    width = 0.34

    ax1.bar([i - width / 2 for i in x], df["fp32_ttt_min"], width=width, color="#8C8C8C", label="FP32")
    ax1.bar([i + width / 2 for i in x], df["kbit_ttt_min"], width=width, color="#61DDAA", label="统一k位")
    ax1.set_xticks(list(x))
    ax1.set_xticklabels(df["model"])
    ax1.set_ylabel("达到目标损失的时间（min）", fontsize=16)
    ax1.set_title("端到端收敛时间", fontsize=18)
    ax1.grid(axis="y", linestyle="--", alpha=0.3)
    ax1.legend(frameon=False, fontsize=14)

    fp32_tp_col = "fp32_tokens_per_s" if "fp32_tokens_per_s" in df.columns else "fp32_throughput_metric"
    kbit_tp_col = "kbit_tokens_per_s" if "kbit_tokens_per_s" in df.columns else "kbit_throughput_metric"
    ax2.bar([i - width / 2 for i in x], df[fp32_tp_col], width=width, color="#8C8C8C", label="FP32")
    ax2.bar([i + width / 2 for i in x], df[kbit_tp_col], width=width, color="#61DDAA", label="统一k位")
    ax2.set_xticks(list(x))
    ax2.set_xticklabels(df["model"])
    ax2.set_ylabel("吞吐（tokens/s）", fontsize=16)
    ax2.set_title("不同模型的端到端吞吐", fontsize=18)
    ax2.grid(axis="y", linestyle="--", alpha=0.3)

    _save(fig, "ch3-multi-model-e2e.svg")


def draw_ch3_validation_loss_curve() -> None:
    df = pd.read_csv(CSV_DIR / "ch3_validation_loss_curve.csv")

    fig, ax = plt.subplots(figsize=(9.2, 4.2))

    ax.plot(df["step"], df["fp32_val_loss"], marker="o", linewidth=2.2, color="#8C8C8C", label="FP32")
    ax.plot(df["step"], df["k4_val_loss"], marker="s", linewidth=2.2, color="#61DDAA", label="4位")

    ax.set_xlabel("训练步数", fontsize=16)
    ax.set_ylabel("验证损失", fontsize=16)
    ax.set_title("典型跨域链路下的验证损失曲线", fontsize=18)
    ax.grid(True, linestyle="--", alpha=0.3)
    ax.legend(frameon=False, fontsize=14)

    _save(fig, "ch3-validation-loss-curve.svg")


def draw_ch4_comm_asymmetry() -> None:
    df = pd.read_csv(CSV_DIR / "ch4_comm_asymmetry.csv")

    fig, ax = plt.subplots(figsize=(8.8, 4.2))
    bars = ax.bar(df["link_type"], df["bandwidth_gbps"], color=["#5B8FF9", "#F6BD16", "#E8684A"])
    ax.set_yscale("log")
    ax.set_ylabel("带宽（Gbps，对数刻度）", fontsize=16)
    ax.set_title("通信域带宽非对称性", fontsize=18)
    ax.grid(axis="y", linestyle="--", alpha=0.3)

    for b, v in zip(bars, df["bandwidth_gbps"]):
        ax.text(b.get_x() + b.get_width() / 2.0, v, f"{int(v)}", ha="center", va="bottom", fontsize=14)

    _save(fig, "ch4-comm-asymmetry.svg")


def draw_ch4_e2e_results() -> None:
    df = pd.read_csv(CSV_DIR / "ch4_e2e_results.csv")

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(11.2, 4.2))

    ax1.bar(df["method"], df["throughput_sps"], color=["#8C8C8C", "#5B8FF9", "#61DDAA"])
    ax1.set_ylabel("吞吐（samples/s）", fontsize=16)
    ax1.set_title("端到端吞吐", fontsize=18)
    ax1.grid(axis="y", linestyle="--", alpha=0.3)
    ax1.tick_params(axis="x", rotation=12)

    ax2.bar(df["method"], df["iter_time_ms"], color=["#8C8C8C", "#5B8FF9", "#61DDAA"], label="迭代时间")
    ax2.plot(df["method"], df["comm_time_ms"], color="#E8684A", marker="o", linewidth=2, label="通信时间")
    ax2.set_ylabel("时间（ms）", fontsize=16)
    ax2.set_title("迭代时间与通信时间", fontsize=18)
    ax2.grid(axis="y", linestyle="--", alpha=0.3)
    ax2.tick_params(axis="x", rotation=12)
    ax2.legend(frameon=False, fontsize=14)

    _save(fig, "ch4-e2e-results.svg")


def draw_ch4_chunk_sensitivity() -> None:
    df = pd.read_csv(CSV_DIR / "ch4_chunk_sensitivity.csv")

    fig, ax1 = plt.subplots(figsize=(9.2, 4.2))
    ax1.plot(df["chunks"], df["comm_time_ms"], marker="o", linewidth=2.2, color="#5B8FF9", label="通信时间")
    ax1.set_xlabel("分块数量", fontsize=16)
    ax1.set_ylabel("通信时间（ms）", color="#5B8FF9", fontsize=16)
    ax1.tick_params(axis="y", labelcolor="#5B8FF9")
    ax1.grid(True, linestyle="--", alpha=0.3)

    ax2 = ax1.twinx()
    ax2.plot(df["chunks"], df["speedup"], marker="s", linewidth=2.2, color="#E8684A", label="加速比")
    ax2.set_ylabel("加速比（x）", color="#E8684A", fontsize=16)
    ax2.tick_params(axis="y", labelcolor="#E8684A")

    ax1.set_title("管线式分层全归约的分块敏感性", fontsize=18)

    _save(fig, "ch4-chunk-sensitivity.svg")


def draw_ch4_bandwidth_ratio_3factor() -> None:
    df = pd.read_csv(CSV_DIR / "ch4_tab_bandwidth_ratio_3factor.csv")

    fig, ax = plt.subplots(figsize=(9.8, 4.4))

    # Fixed tensor size, compare chunk curves under different bandwidth ratios.
    for chunk, group in df.groupby("chunk"):
        group = group.copy()
        group["ratio_num"] = group["bandwidth_ratio"].apply(lambda x: float(str(x).split(":")[0]))
        group = group.sort_values("ratio_num")
        ratios = list(group["ratio_num"])
        speedups = [float(str(x).replace("x", "")) for x in group["speedup"]]
        ax.plot(ratios, speedups, marker="o", linewidth=2.2, label=f"分块={chunk}")

    ax.set_xlabel("域内/域间带宽比", fontsize=16)
    ax.set_ylabel("加速比（x）", fontsize=16)
    ax.set_title("固定张量(1024MB)：带宽非对称下的分块曲线", fontsize=18)
    ax.set_xticks([5, 10, 20, 30])
    ax.grid(True, linestyle="--", alpha=0.3)
    ax.legend(frameon=False, fontsize=14)

    _save(fig, "ch4-bandwidth-ratio-3factor.svg")


def draw_ch4_expA_bandwidth_throttle_3factor() -> None:
    df = pd.read_csv(CSV_DIR / "ch4_tab_expA_bandwidth_throttle_3factor.csv")

    fig, ax = plt.subplots(figsize=(10.2, 4.4))
    x = list(range(len(df)))
    tensor_proxy = [int(str(v).split("/")[0].strip().replace("MB", "")) for v in df["comm_tensor_size"]]

    bars = ax.bar(x, tensor_proxy, color="#5B8FF9", alpha=0.85)
    ax.set_xticks(x)
    ax.set_xticklabels(df["exp_id"])
    ax.set_ylabel("通信张量规模代理值（MB）", fontsize=16)
    ax.set_xlabel("带宽退化案例", fontsize=16)
    ax.set_title("实验A：三因素控制下的带宽限速", fontsize=18)
    ax.grid(axis="y", linestyle="--", alpha=0.3)
    ax.set_ylim(0, max(tensor_proxy) * 1.25)

    for bar, bw, rtt, chunk in zip(bars, df["inter_bandwidth"], df["inter_rtt"], df["chunk_size"]):
        ax.text(
            bar.get_x() + bar.get_width() / 2,
            bar.get_height() + 10,
            f"{bw}，{rtt}\n{chunk}",
            ha="center",
            va="bottom",
            fontsize=14,
        )

    _save(fig, "ch4-expA-bandwidth-throttle-3factor.svg")


def draw_ch4_expB_rtt_escalation_3factor() -> None:
    df = pd.read_csv(CSV_DIR / "ch4_tab_expB_rtt_escalation_3factor.csv")

    fig, ax = plt.subplots(figsize=(10.2, 4.4))
    x = list(range(len(df)))
    rtt_vals = [float(str(v).replace("ms", "").strip()) for v in df["inter_rtt"]]
    tensor_proxy = [int(str(v).split("/")[0].strip().replace("MB", "")) for v in df["comm_tensor_size"]]

    ax.plot(x, rtt_vals, marker="o", linewidth=2.2, color="#E8684A", label="RTT（ms）")
    ax.set_ylabel("RTT（ms）", color="#E8684A", fontsize=16)
    ax.tick_params(axis="y", labelcolor="#E8684A")
    ax.set_xticks(x)
    ax.set_xticklabels(df["exp_id"])
    ax.set_xlabel("RTT提升案例", fontsize=16)
    ax.grid(True, linestyle="--", alpha=0.3)

    ax2 = ax.twinx()
    ax2.bar(x, tensor_proxy, color="#61DDAA", alpha=0.45, label="张量代理值（MB）")
    ax2.set_ylabel("通信张量规模代理值（MB）", color="#61DDAA", fontsize=16)
    ax2.tick_params(axis="y", labelcolor="#61DDAA")

    for i, chunk in enumerate(df["chunk_size"]):
        ax.text(i, rtt_vals[i] + 4, chunk, ha="center", va="bottom", fontsize=14)

    ax.set_title("实验B：RTT提升与张量/分块耦合", fontsize=18)

    _save(fig, "ch4-expB-rtt-escalation-3factor.svg")


def draw_ch4_expC_jitter_loss_3factor() -> None:
    df = pd.read_csv(CSV_DIR / "ch4_tab_expC_jitter_loss_3factor.csv")

    fig, ax = plt.subplots(figsize=(10.2, 4.4))
    x = list(range(len(df)))
    jitter_vals = [float(str(v).replace("ms", "").strip()) for v in df["jitter"]]
    loss_vals = [float(str(v).replace("%", "").strip()) for v in df["loss_rate"]]

    width = 0.35
    ax.bar([i - width / 2 for i in x], jitter_vals, width=width, color="#5B8FF9", label="抖动（ms）")
    ax.bar([i + width / 2 for i in x], loss_vals, width=width, color="#F6BD16", label="丢包率（%）")

    ax.set_xticks(x)
    ax.set_xticklabels(df["exp_id"])
    ax.set_ylabel("数值", fontsize=16)
    ax.set_xlabel("抖动/丢包案例", fontsize=16)
    ax.set_title("实验C：三因素控制下的抖动+丢包", fontsize=18)
    ax.grid(axis="y", linestyle="--", alpha=0.3)
    ax.legend(frameon=False, fontsize=14)

    for i, txt in enumerate(df["chunk_size"]):
        ax.text(i, max(jitter_vals[i], loss_vals[i]) + 1.5, txt, ha="center", va="bottom", fontsize=14)

    _save(fig, "ch4-expC-jitter-loss-3factor.svg")


def main() -> None:
    _configure_plot_style()
    draw_ch3_comm_bottleneck()
    draw_ch3_experiment_results()
    draw_ch3_method_comparison()
    draw_ch3_multimodel_e2e()
    draw_ch3_validation_loss_curve()
    draw_ch4_comm_asymmetry()
    draw_ch4_e2e_results()
    draw_ch4_chunk_sensitivity()
    draw_ch4_bandwidth_ratio_3factor()
    draw_ch4_expA_bandwidth_throttle_3factor()
    draw_ch4_expB_rtt_escalation_3factor()
    draw_ch4_expC_jitter_loss_3factor()


if __name__ == "__main__":
    main()
