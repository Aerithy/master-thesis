from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
CSV_DIR = ROOT / "image" / "csv"
IMG_DIR = ROOT / "image"


def _configure_plot_style() -> None:
    # Keep text editable in SVG and enforce Times New Roman for all chart text.
    plt.rcParams["svg.fonttype"] = "none"
    plt.rcParams["font.family"] = "Times New Roman"
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
    ax1.set_ylabel("Communication Volume per Iteration (MiB, log scale)")
    ax1.set_xticks(list(x))
    ax1.set_xticklabels(df["model"], rotation=0)
    ax1.set_title("Communication Bottleneck Across Model Scales")
    ax1.grid(axis="y", linestyle="--", alpha=0.3)

    ax2 = ax1.twinx()
    ax2.plot(list(x), df["comm_share_percent"], color="#E8684A", marker="o", linewidth=2.2)
    ax2.set_ylabel("Communication Time Share (%)")
    ax2.set_ylim(0, 100)

    for b, val in zip(bars, df["comm_per_iter_mib"]):
        ax1.text(b.get_x() + b.get_width() / 2.0, val, f"{val:,.0f}", ha="center", va="bottom", fontsize=10)

    _save(fig, "ch3-comm-bottleneck.svg")


def draw_ch3_experiment_results() -> None:
    df = pd.read_csv(CSV_DIR / "ch3_experiment_results.csv")

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(11.2, 4.2))

    for col, label, color in [
        ("fp32_tokens_per_s", "FP32", "#8C8C8C"),
        ("k8_tokens_per_s", "8-bit", "#5B8FF9"),
        ("k4_tokens_per_s", "4-bit", "#61DDAA"),
        ("k2_tokens_per_s", "2-bit", "#F6BD16"),
        ("k1_tokens_per_s", "1-bit", "#E8684A"),
    ]:
        ax1.plot(df["bandwidth_mbps"], df[col], marker="o", linewidth=2, label=label, color=color)

    ax1.set_xscale("log")
    ax1.set_xlabel("Cross-domain Bandwidth (Mbps, log scale)")
    ax1.set_ylabel("Throughput (tokens/s)")
    ax1.set_title("Speedup Under Bandwidth Constraints")
    ax1.grid(True, linestyle="--", alpha=0.3)
    ax1.legend(frameon=False, fontsize=10)

    for col, label, color in [
        ("fp32_final_loss", "FP32", "#8C8C8C"),
        ("k8_final_loss", "8-bit", "#5B8FF9"),
        ("k4_final_loss", "4-bit", "#61DDAA"),
        ("k2_final_loss", "2-bit", "#F6BD16"),
        ("k1_final_loss", "1-bit", "#E8684A"),
    ]:
        ax2.plot(df["bandwidth_mbps"], df[col], marker="s", linewidth=2, label=label, color=color)

    ax2.set_xscale("log")
    ax2.set_xlabel("Cross-domain Bandwidth (Mbps, log scale)")
    ax2.set_ylabel("Final Validation Loss")
    ax2.set_title("Convergence Stability vs Quantization Bits")
    ax2.grid(True, linestyle="--", alpha=0.3)

    _save(fig, "ch3-experiment-results.svg")


def draw_ch3_method_comparison() -> None:
    df = pd.read_csv(CSV_DIR / "ch3_method_comparison.csv")

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(11.2, 4.2))

    colors = ["#8C8C8C", "#5B8FF9", "#F6BD16", "#E8684A", "#61DDAA"]

    throughput_col = "throughput_tokens_per_s" if "throughput_tokens_per_s" in df.columns else "throughput_metric"
    ax1.bar(df["method"], df[throughput_col], color=colors)
    ax1.set_ylabel("Throughput (tokens/s)")
    ax1.set_title("Method-wise End-to-End Throughput")
    ax1.grid(axis="y", linestyle="--", alpha=0.3)
    ax1.tick_params(axis="x", rotation=15)

    ax2.bar(df["method"], df["comm_share_percent"], color=colors, alpha=0.9, label="Comm Share")
    ax2.plot(df["method"], df["p95_tail_ms"], color="#3D76DD", marker="o", linewidth=2.0, label="P95 Tail (ms)")
    ax2.set_ylabel("Comm Share (%) / Tail Latency (ms)")
    ax2.set_title("Communication Cost and Tail Latency")
    ax2.grid(axis="y", linestyle="--", alpha=0.3)
    ax2.tick_params(axis="x", rotation=15)
    ax2.legend(frameon=False, fontsize=10)

    _save(fig, "ch3-method-comparison.svg")


def draw_ch3_multimodel_e2e() -> None:
    df = pd.read_csv(CSV_DIR / "ch3_multimodel_e2e.csv")

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(11.2, 4.2))

    x = range(len(df))
    width = 0.34

    ax1.bar([i - width / 2 for i in x], df["fp32_ttt_min"], width=width, color="#8C8C8C", label="FP32")
    ax1.bar([i + width / 2 for i in x], df["kbit_ttt_min"], width=width, color="#61DDAA", label="Unified k-bit")
    ax1.set_xticks(list(x))
    ax1.set_xticklabels(df["model"])
    ax1.set_ylabel("Time to Target Loss (min)")
    ax1.set_title("End-to-End Convergence Time")
    ax1.grid(axis="y", linestyle="--", alpha=0.3)
    ax1.legend(frameon=False, fontsize=10)

    fp32_tp_col = "fp32_tokens_per_s" if "fp32_tokens_per_s" in df.columns else "fp32_throughput_metric"
    kbit_tp_col = "kbit_tokens_per_s" if "kbit_tokens_per_s" in df.columns else "kbit_throughput_metric"
    ax2.bar([i - width / 2 for i in x], df[fp32_tp_col], width=width, color="#8C8C8C", label="FP32")
    ax2.bar([i + width / 2 for i in x], df[kbit_tp_col], width=width, color="#61DDAA", label="Unified k-bit")
    ax2.set_xticks(list(x))
    ax2.set_xticklabels(df["model"])
    ax2.set_ylabel("Throughput (tokens/s)")
    ax2.set_title("End-to-End Throughput Across Models")
    ax2.grid(axis="y", linestyle="--", alpha=0.3)

    _save(fig, "ch3-multi-model-e2e.svg")


def draw_ch4_comm_asymmetry() -> None:
    df = pd.read_csv(CSV_DIR / "ch4_comm_asymmetry.csv")

    fig, ax = plt.subplots(figsize=(8.8, 4.2))
    bars = ax.bar(df["link_type"], df["bandwidth_gbps"], color=["#5B8FF9", "#F6BD16", "#E8684A"])
    ax.set_yscale("log")
    ax.set_ylabel("Bandwidth (Gbps, log scale)")
    ax.set_title("Bandwidth Asymmetry Across Communication Domains")
    ax.grid(axis="y", linestyle="--", alpha=0.3)

    for b, v in zip(bars, df["bandwidth_gbps"]):
        ax.text(b.get_x() + b.get_width() / 2.0, v, f"{int(v)}", ha="center", va="bottom", fontsize=11)

    _save(fig, "ch4-comm-asymmetry.svg")


def draw_ch4_e2e_results() -> None:
    df = pd.read_csv(CSV_DIR / "ch4_e2e_results.csv")

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(11.2, 4.2))

    ax1.bar(df["method"], df["throughput_sps"], color=["#8C8C8C", "#5B8FF9", "#61DDAA"])
    ax1.set_ylabel("Throughput (samples/s)")
    ax1.set_title("End-to-End Throughput")
    ax1.grid(axis="y", linestyle="--", alpha=0.3)
    ax1.tick_params(axis="x", rotation=12)

    ax2.bar(df["method"], df["iter_time_ms"], color=["#8C8C8C", "#5B8FF9", "#61DDAA"], label="Iteration Time")
    ax2.plot(df["method"], df["comm_time_ms"], color="#E8684A", marker="o", linewidth=2, label="Communication Time")
    ax2.set_ylabel("Time (ms)")
    ax2.set_title("Iteration and Communication Time")
    ax2.grid(axis="y", linestyle="--", alpha=0.3)
    ax2.tick_params(axis="x", rotation=12)
    ax2.legend(frameon=False, fontsize=10)

    _save(fig, "ch4-e2e-results.svg")


def draw_ch4_chunk_sensitivity() -> None:
    df = pd.read_csv(CSV_DIR / "ch4_chunk_sensitivity.csv")

    fig, ax1 = plt.subplots(figsize=(9.2, 4.2))
    ax1.plot(df["chunks"], df["comm_time_ms"], marker="o", linewidth=2.2, color="#5B8FF9", label="Communication Time")
    ax1.set_xlabel("Number of Chunks")
    ax1.set_ylabel("Communication Time (ms)", color="#5B8FF9")
    ax1.tick_params(axis="y", labelcolor="#5B8FF9")
    ax1.grid(True, linestyle="--", alpha=0.3)

    ax2 = ax1.twinx()
    ax2.plot(df["chunks"], df["speedup"], marker="s", linewidth=2.2, color="#E8684A", label="Speedup")
    ax2.set_ylabel("Speedup (x)", color="#E8684A")
    ax2.tick_params(axis="y", labelcolor="#E8684A")

    ax1.set_title("Chunk-size Sensitivity for Pipelined Hierarchical All-Reduce")

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
        ax.plot(ratios, speedups, marker="o", linewidth=2.2, label=f"chunk={chunk}")

    ax.set_xlabel("Intra/Inter Bandwidth Ratio")
    ax.set_ylabel("Speedup (x)")
    ax.set_title("Fixed Tensor (1024MB): Chunk Curves under Bandwidth Asymmetry")
    ax.set_xticks([5, 10, 20, 30])
    ax.grid(True, linestyle="--", alpha=0.3)
    ax.legend(frameon=False, fontsize=11)

    _save(fig, "ch4-bandwidth-ratio-3factor.svg")


def draw_ch4_expA_bandwidth_throttle_3factor() -> None:
    df = pd.read_csv(CSV_DIR / "ch4_tab_expA_bandwidth_throttle_3factor.csv")

    fig, ax = plt.subplots(figsize=(10.2, 4.4))
    x = list(range(len(df)))
    tensor_proxy = [int(str(v).split("/")[0].strip().replace("MB", "")) for v in df["comm_tensor_size"]]

    bars = ax.bar(x, tensor_proxy, color="#5B8FF9", alpha=0.85)
    ax.set_xticks(x)
    ax.set_xticklabels(df["exp_id"])
    ax.set_ylabel("Communication Tensor Size Proxy (MB)")
    ax.set_xlabel("Bandwidth-degradation Cases")
    ax.set_title("Exp-A: Bandwidth Throttling under 3-factor Control")
    ax.grid(axis="y", linestyle="--", alpha=0.3)

    for idx, (bar, bw, rtt, chunk) in enumerate(zip(bars, df["inter_bandwidth"], df["inter_rtt"], df["chunk_size"])):
        ax.text(
            bar.get_x() + bar.get_width() / 2,
            bar.get_height() + 10,
            f"{bw}, {rtt}\n{chunk}",
            ha="center",
            va="bottom",
            fontsize=10,
        )

    _save(fig, "ch4-expA-bandwidth-throttle-3factor.svg")


def draw_ch4_expB_rtt_escalation_3factor() -> None:
    df = pd.read_csv(CSV_DIR / "ch4_tab_expB_rtt_escalation_3factor.csv")

    fig, ax = plt.subplots(figsize=(10.2, 4.4))
    x = list(range(len(df)))
    rtt_vals = [float(str(v).replace("ms", "").strip()) for v in df["inter_rtt"]]
    tensor_proxy = [int(str(v).split("/")[0].strip().replace("MB", "")) for v in df["comm_tensor_size"]]

    ax.plot(x, rtt_vals, marker="o", linewidth=2.2, color="#E8684A", label="RTT (ms)")
    ax.set_ylabel("RTT (ms)", color="#E8684A")
    ax.tick_params(axis="y", labelcolor="#E8684A")
    ax.set_xticks(x)
    ax.set_xticklabels(df["exp_id"])
    ax.set_xlabel("RTT-escalation Cases")
    ax.grid(True, linestyle="--", alpha=0.3)

    ax2 = ax.twinx()
    ax2.bar(x, tensor_proxy, color="#61DDAA", alpha=0.45, label="Tensor Proxy (MB)")
    ax2.set_ylabel("Communication Tensor Size Proxy (MB)", color="#61DDAA")
    ax2.tick_params(axis="y", labelcolor="#61DDAA")

    for i, chunk in enumerate(df["chunk_size"]):
        ax.text(i, rtt_vals[i] + 4, chunk, ha="center", va="bottom", fontsize=10)

    ax.set_title("Exp-B: RTT Escalation with Tensor/Chunk Coupling")

    _save(fig, "ch4-expB-rtt-escalation-3factor.svg")


def draw_ch4_expC_jitter_loss_3factor() -> None:
    df = pd.read_csv(CSV_DIR / "ch4_tab_expC_jitter_loss_3factor.csv")

    fig, ax = plt.subplots(figsize=(10.2, 4.4))
    x = list(range(len(df)))
    jitter_vals = [float(str(v).replace("ms", "").strip()) for v in df["jitter"]]
    loss_vals = [float(str(v).replace("%", "").strip()) for v in df["loss_rate"]]

    width = 0.35
    ax.bar([i - width / 2 for i in x], jitter_vals, width=width, color="#5B8FF9", label="Jitter (ms)")
    ax.bar([i + width / 2 for i in x], loss_vals, width=width, color="#F6BD16", label="Loss Rate (%)")

    ax.set_xticks(x)
    ax.set_xticklabels(df["exp_id"])
    ax.set_ylabel("Value")
    ax.set_xlabel("Jitter/Loss Cases")
    ax.set_title("Exp-C: Jitter+Loss under 3-factor Control")
    ax.grid(axis="y", linestyle="--", alpha=0.3)
    ax.legend(frameon=False, fontsize=11)

    for i, txt in enumerate(df["chunk_size"]):
        ax.text(i, max(jitter_vals[i], loss_vals[i]) + 1.5, txt, ha="center", va="bottom", fontsize=10)

    _save(fig, "ch4-expC-jitter-loss-3factor.svg")


def main() -> None:
    _configure_plot_style()
    draw_ch3_comm_bottleneck()
    draw_ch3_experiment_results()
    draw_ch3_method_comparison()
    draw_ch3_multimodel_e2e()
    draw_ch4_comm_asymmetry()
    draw_ch4_e2e_results()
    draw_ch4_chunk_sensitivity()
    draw_ch4_bandwidth_ratio_3factor()
    draw_ch4_expA_bandwidth_throttle_3factor()
    draw_ch4_expB_rtt_escalation_3factor()
    draw_ch4_expC_jitter_loss_3factor()


if __name__ == "__main__":
    main()
