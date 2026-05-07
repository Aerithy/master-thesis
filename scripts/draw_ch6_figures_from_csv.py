from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
CSV_DIR = ROOT / "image" / "csv"
IMG_DIR = ROOT / "image"


def _configure_plot_style() -> None:
    # Convert text to paths in SVG to avoid font issues during Typst PDF export.
    plt.rcParams["svg.fonttype"] = "path"
    plt.rcParams["font.family"] = ["Times New Roman", "SimSun"]
    plt.rcParams["mathtext.fontset"] = "stix"
    plt.rcParams["axes.unicode_minus"] = False
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


def draw_ch6_system_performance_compare() -> None:
    df = pd.read_csv(CSV_DIR / "ch6_system_perf_compare.csv")

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(11.2, 4.4))
    x = list(range(len(df)))
    width = 0.34

    ax1.bar([i - width / 2 for i in x], df["baseline_throughput"], width=width, color="#8C8C8C", label="基线")
    ax1.bar([i + width / 2 for i in x], df["system_throughput"], width=width, color="#61DDAA", label="完整系统")
    ax1.set_xticks(x)
    ax1.set_xticklabels(df["network_group"])
    ax1.set_ylabel("吞吐（tokens/s）", fontsize=16)
    ax1.set_title("固定模型/批次下的吞吐对比", fontsize=18)
    ax1.grid(axis="y", linestyle="--", alpha=0.3)
    ax1.legend(frameon=False, fontsize=14)

    ax2.plot(df["network_group"], df["baseline_iter_ms"], marker="o", linewidth=2.2, color="#8C8C8C", label="迭代时间-基线")
    ax2.plot(df["network_group"], df["system_iter_ms"], marker="o", linewidth=2.2, color="#61DDAA", label="迭代时间-完整")
    ax2.plot(df["network_group"], df["baseline_comm_share"], marker="s", linewidth=2.0, color="#E8684A", label="通信时间-基线")
    ax2.plot(df["network_group"], df["system_comm_share"], marker="s", linewidth=2.0, color="#5B8FF9", label="通信时间-完整")
    ax2.set_ylabel("迭代时间（ms）/通信时间（ms）", fontsize=16)
    ax2.set_title("迭代时间与通信时间", fontsize=18)
    ax2.grid(True, linestyle="--", alpha=0.3)
    ax2.legend(frameon=False, fontsize=14)

    _save(fig, "ch6-system-performance-compare.svg")


def draw_ch6_system_loss_curves() -> None:
    step_df = pd.read_csv(CSV_DIR / "ch6_system_loss_curves_step.csv")
    time_df = pd.read_csv(CSV_DIR / "ch6_system_loss_curves_time.csv")

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(11.2, 4.4))

    ax1.plot(step_df["step"], step_df["baseline_loss"], marker="o", linewidth=2.2, color="#8C8C8C", label="基线")
    ax1.plot(step_df["step"], step_df["system_loss"], marker="s", linewidth=2.2, color="#61DDAA", label="完整系统")
    ax1.set_xlabel("训练步数", fontsize=16)
    ax1.set_ylabel("验证损失", fontsize=16)
    ax1.set_title("对齐步数的损失曲线", fontsize=18)
    ax1.grid(True, linestyle="--", alpha=0.3)
    ax1.legend(frameon=False, fontsize=14)

    ax2.plot(time_df["minute"], time_df["baseline_loss"], marker="o", linewidth=2.2, color="#8C8C8C", label="基线")
    ax2.plot(time_df["minute"], time_df["system_loss"], marker="s", linewidth=2.2, color="#61DDAA", label="完整系统")
    ax2.set_xlabel("墙钟时间（min）", fontsize=16)
    ax2.set_ylabel("验证损失", fontsize=16)
    ax2.set_title("对齐时间的损失曲线", fontsize=18)
    ax2.grid(True, linestyle="--", alpha=0.3)
    ax2.legend(frameon=False, fontsize=14)

    _save(fig, "ch6-system-loss-curves.svg")


def draw_ch6_system_degradation() -> None:
    df = pd.read_csv(CSV_DIR / "ch6_system_degradation_test.csv")

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(11.2, 4.4))

    x = list(range(len(df)))
    width = 0.34
    ax1.bar([i - width / 2 for i in x], df["baseline_throughput"], width=width, color="#8C8C8C", label="基线")
    ax1.bar([i + width / 2 for i in x], df["system_throughput"], width=width, color="#61DDAA", label="完整系统")
    ax1.set_xticks(x)
    ax1.set_xticklabels(df["scenario"], rotation=12)
    ax1.set_ylabel("吞吐（items/s）", fontsize=16)
    ax1.set_title("退化测试：吞吐与回退一致性", fontsize=18)
    ax1.grid(axis="y", linestyle="--", alpha=0.3)
    ax1.legend(frameon=False, fontsize=14)

    ax2.plot(df["scenario"], df["speedup"], marker="o", linewidth=2.2, color="#E8684A", label="加速比")
    ax2.plot(df["scenario"], df["rollback_ratio"], marker="s", linewidth=2.2, color="#5B8FF9", label="回退比例")
    ax2.plot(df["scenario"], df["final_loss_gap"], marker="^", linewidth=2.2, color="#F6BD16", label="最终损失差")
    ax2.set_ylabel("数值", fontsize=16)
    ax2.set_title("加速/自动回退/收敛差距", fontsize=18)
    ax2.grid(True, linestyle="--", alpha=0.3)
    ax2.legend(frameon=False, fontsize=14)

    _save(fig, "ch6-system-degradation.svg")


def main() -> None:
    _configure_plot_style()
    draw_ch6_system_performance_compare()
    draw_ch6_system_loss_curves()
    draw_ch6_system_degradation()


if __name__ == "__main__":
    main()
