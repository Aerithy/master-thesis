from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
CSV_DIR = ROOT / "image" / "csv"
IMG_DIR = ROOT / "image"


def _configure_plot_style() -> None:
    plt.rcParams["svg.fonttype"] = "none"
    plt.rcParams["font.family"] = "Times New Roman"
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

    ax1.bar([i - width / 2 for i in x], df["baseline_throughput"], width=width, color="#8C8C8C", label="Baseline")
    ax1.bar([i + width / 2 for i in x], df["system_throughput"], width=width, color="#61DDAA", label="Full System")
    ax1.set_xticks(x)
    ax1.set_xticklabels(df["network_group"])
    ax1.set_ylabel("Throughput (items/s)")
    ax1.set_title("Throughput Comparison Under Fixed Model/Batch")
    ax1.grid(axis="y", linestyle="--", alpha=0.3)
    ax1.legend(frameon=False)

    ax2.plot(df["network_group"], df["baseline_iter_ms"], marker="o", linewidth=2.2, color="#8C8C8C", label="Iter Time - Baseline")
    ax2.plot(df["network_group"], df["system_iter_ms"], marker="o", linewidth=2.2, color="#61DDAA", label="Iter Time - Full")
    ax2.plot(df["network_group"], df["baseline_comm_share"], marker="s", linewidth=2.0, color="#E8684A", label="Comm Share - Baseline")
    ax2.plot(df["network_group"], df["system_comm_share"], marker="s", linewidth=2.0, color="#5B8FF9", label="Comm Share - Full")
    ax2.set_ylabel("Iter Time (ms) / Comm Share (%)")
    ax2.set_title("Iteration Time and Communication Share")
    ax2.grid(True, linestyle="--", alpha=0.3)
    ax2.legend(frameon=False, fontsize=9)

    _save(fig, "ch6-system-performance-compare.svg")


def draw_ch6_system_loss_curves() -> None:
    step_df = pd.read_csv(CSV_DIR / "ch6_system_loss_curves_step.csv")
    time_df = pd.read_csv(CSV_DIR / "ch6_system_loss_curves_time.csv")

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(11.2, 4.4))

    ax1.plot(step_df["step"], step_df["baseline_loss"], marker="o", linewidth=2.2, color="#8C8C8C", label="Baseline")
    ax1.plot(step_df["step"], step_df["system_loss"], marker="s", linewidth=2.2, color="#61DDAA", label="Full System")
    ax1.set_xlabel("Training Step")
    ax1.set_ylabel("Validation Loss")
    ax1.set_title("Step-aligned Loss Curves")
    ax1.grid(True, linestyle="--", alpha=0.3)
    ax1.legend(frameon=False)

    ax2.plot(time_df["minute"], time_df["baseline_loss"], marker="o", linewidth=2.2, color="#8C8C8C", label="Baseline")
    ax2.plot(time_df["minute"], time_df["system_loss"], marker="s", linewidth=2.2, color="#61DDAA", label="Full System")
    ax2.set_xlabel("Wall-clock Time (min)")
    ax2.set_ylabel("Validation Loss")
    ax2.set_title("Wall-clock-aligned Loss Curves")
    ax2.grid(True, linestyle="--", alpha=0.3)

    _save(fig, "ch6-system-loss-curves.svg")


def draw_ch6_system_degradation() -> None:
    df = pd.read_csv(CSV_DIR / "ch6_system_degradation_test.csv")

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(11.2, 4.4))

    x = list(range(len(df)))
    width = 0.34
    ax1.bar([i - width / 2 for i in x], df["baseline_throughput"], width=width, color="#8C8C8C", label="Baseline")
    ax1.bar([i + width / 2 for i in x], df["system_throughput"], width=width, color="#61DDAA", label="Full System")
    ax1.set_xticks(x)
    ax1.set_xticklabels(df["scenario"], rotation=12)
    ax1.set_ylabel("Throughput (items/s)")
    ax1.set_title("Degradation Test: Throughput and Fallback Consistency")
    ax1.grid(axis="y", linestyle="--", alpha=0.3)
    ax1.legend(frameon=False)

    ax2.plot(df["scenario"], df["speedup"], marker="o", linewidth=2.2, color="#E8684A", label="Speedup")
    ax2.plot(df["scenario"], df["rollback_ratio"], marker="s", linewidth=2.2, color="#5B8FF9", label="Rollback Ratio")
    ax2.plot(df["scenario"], df["final_loss_gap"], marker="^", linewidth=2.2, color="#F6BD16", label="Final Loss Gap")
    ax2.set_ylabel("Value")
    ax2.set_title("Speedup/Auto-fallback/Convergence Gap")
    ax2.grid(True, linestyle="--", alpha=0.3)
    ax2.legend(frameon=False)

    _save(fig, "ch6-system-degradation.svg")


def main() -> None:
    _configure_plot_style()
    draw_ch6_system_performance_compare()
    draw_ch6_system_loss_curves()
    draw_ch6_system_degradation()


if __name__ == "__main__":
    main()
