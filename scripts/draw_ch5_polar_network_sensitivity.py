import pandas as pd
import matplotlib.pyplot as plt
from matplotlib import font_manager

# =========================
# 读取 CSV
# =========================
csv_path = "./image/csv/ch5_polar_network_sensitivity.csv"
font_path = "C:/Windows/Fonts/simsun.ttc"

my_font = font_manager.FontProperties(fname=font_path)

df = pd.read_csv(csv_path)

# CSV 格式应类似：
# Bandwidth,Baseline(tokens/s),Proposed(tokens/s)
# 100Mbps,11200,11800
# 300Mbps,15500,20500
# ...

x_labels = df["Bandwidth"]

baseline = df["Baseline(tokens/s)"]
proposed = df["Proposed(tokens/s)"]

# =========================
# 作图风格
# =========================
plt.rcParams.update({
    # "font.family": "serif",
    "font.size": 16,
    "axes.unicode_minus": False
})

fig, ax = plt.subplots(figsize=(10.5, 6.5), dpi=200)

# 网格
ax.grid(True, alpha=0.25)

# =========================
# 曲线
# =========================
ax.plot(
    x_labels,
    baseline,
    linewidth=2.5,
    marker='o',
    markersize=5,
    # fontproperties=my_font,
    label='基线'
)

ax.plot(
    x_labels,
    proposed,
    linewidth=2.5,
    marker='o',
    markersize=5,
    # fontproperties=my_font,
    label='本文方法',
)

# =========================
# 坐标轴
# =========================
ax.set_xlabel("网络带宽", fontsize=22, fontproperties=my_font)
ax.set_ylabel("吞吐量（tokens/s）", fontsize=22, fontproperties=my_font)

ax.tick_params(axis='x', labelsize=14)
ax.tick_params(axis='y', labelsize=14)

# Y 轴范围
y_min = min(min(baseline), min(proposed)) * 0.8
y_max = max(max(baseline), max(proposed)) * 1.05
ax.set_ylim(y_min, y_max)

# =========================
# 图例
# =========================
ax.legend(
    fontsize=24,
    frameon=True,
    fancybox=True,
    framealpha=0.95,
    loc='lower right',
    prop=my_font
)

# 边框透明度
for spine in ax.spines.values():
    spine.set_alpha(0.25)

plt.tight_layout()

# =========================
# 保存
# =========================
plt.savefig(
    "network_bandwidth_throughput.png",
    bbox_inches='tight'
)

plt.show()