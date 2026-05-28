import os
from pathlib import Path
import pandas as pd
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt

# 用法：python replot_extracted_figures.py
# 默认读取同目录下 aligned_extracted_data.csv，并输出三张 PNG。

# BASE_DIR = os.path.dirname(os.path.abspath(__file__))
BASE_DIR = Path(__file__).resolve().parents[1]
CSV_PATH = os.path.join(BASE_DIR, "image/csv/ch5_loss_curve.csv")
OUT_DIR = os.path.join(BASE_DIR, "image/replotted_figures")
os.makedirs(OUT_DIR, exist_ok=True)

# 中文字体兜底：系统有哪个就用哪个；没有时仍可画图，但中文可能显示为方框。
plt.rcParams["font.sans-serif"] = [
    "SimHei", "Microsoft YaHei", "Noto Sans CJK SC", "Arial Unicode MS", "DejaVu Sans"
]
plt.rcParams["axes.unicode_minus"] = False


def style_ax(ax, xlabel):
    ax.set_xlabel(xlabel)
    ax.set_ylabel("训练损失")
    ax.grid(True, alpha=0.28)
    ax.set_ylim(0.8, 11.0)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)


def save_convergence(df):
    fig, ax = plt.subplots(figsize=(8.8, 4.8), dpi=180)
    ax.plot(df["step"], df["convergence_DDP_1F1B"], label="DDP+1F1B", linewidth=1.8)
    ax.plot(df["step"], df["convergence_DiLoCo"], label="DiLoCo", linewidth=1.8)
    ax.plot(df["step"], df["convergence_ours"], label="本文方法", linewidth=1.8)
    style_ax(ax, "迭代次数")
    ax.set_title("收敛性实验")
    ax.legend(frameon=True)
    fig.tight_layout()
    path = os.path.join(OUT_DIR, "01_convergence.png")
    fig.savefig(path, bbox_inches="tight")
    plt.close(fig)
    return path


def save_throughput(df):
    fig, ax = plt.subplots(figsize=(8.8, 4.8), dpi=180)
    ax.plot(df["time_min"], df["throughput_DDP_1F1B"], label="DDP+1F1B", linewidth=1.8)
    ax.plot(df["time_min"], df["throughput_DiLoCo"], label="DiLoCo", linewidth=1.8)
    ax.plot(df["time_min"], df["throughput_ours"], label="本文方法", linewidth=1.8)
    style_ax(ax, "相对时间（分钟）")
    ax.set_title("吞吐速率实验")
    ax.legend(frameon=True)

    # 参考原图中的完成时间标注
    completion_marks = [
        (88.6, "本文方法\n(88.6 分钟)", "#2ca02c", -21.5, 2.45),
        (94.0, "DiLoCo\n(94.0 分钟)", "#ff7f0e", 1.3, 2.05),
        (166.1, "DDP+1F1B\n(166.1 分钟)", "#1f77b4", 1.3, 2.05),
    ]
    for x, label, color, x_offset, y in completion_marks:
        ax.axvline(x, linewidth=1.2, alpha=0.75, color=color)
        ax.text(x + x_offset, y, label, fontsize=9, fontweight="bold", color=color)

    fig.tight_layout()
    path = os.path.join(OUT_DIR, "02_throughput.png")
    fig.savefig(path, bbox_inches="tight")
    plt.close(fig)
    return path


def save_ablation(df):
    fig, ax = plt.subplots(figsize=(8.8, 4.8), dpi=180)
    ax.plot(df["step"], df["ablation_no_error_feedback_no_grad_scaling"], label="无误差反馈 & 无梯度缩放", linewidth=1.8)
    ax.plot(df["step"], df["ablation_no_error_feedback"], label="无误差反馈", linewidth=1.8)
    ax.plot(df["step"], df["ablation_no_grad_scaling"], label="无梯度缩放", linewidth=1.8)
    ax.plot(df["step"], df["ablation_ours"], label="本文方法", linewidth=1.8)
    style_ax(ax, "迭代次数")
    ax.set_title("消融实验")
    ax.legend(frameon=True)
    fig.tight_layout()
    path = os.path.join(OUT_DIR, "03_ablation.png")
    fig.savefig(path, bbox_inches="tight")
    plt.close(fig)
    return path


if __name__ == "__main__":
    data = pd.read_csv(CSV_PATH)
    outputs = [save_convergence(data), save_throughput(data), save_ablation(data)]
    print("生成完成：")
    for item in outputs:
        print(item)
