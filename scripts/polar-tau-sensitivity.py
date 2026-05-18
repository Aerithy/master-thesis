import pandas as pd
import matplotlib.pyplot as plt
from matplotlib import font_manager

# =========================
# 中文字体
# =========================

# Linux:
# font_path = "/usr/share/fonts/truetype/noto/NotoSansCJK-Regular.ttc"

# Windows:
# font_path = "C:/Windows/Fonts/simsun.ttc"

# macOS:
# font_path = "/System/Library/Fonts/PingFang.ttc"
font_path = "C:/Windows/Fonts/simsun.ttc"

my_font = font_manager.FontProperties(fname=font_path)

plt.rcParams["axes.unicode_minus"] = False

# =========================
# 读取 CSV
# =========================

df = pd.read_csv("./image/csv/ch5_polar_tau_sensitivity.csv")

tau = df["tau"]
throughput = df["throughput_tokens_per_s"]
df = df[df.index % 4 == 0]
loss = df["final_loss"]
print(loss)

# =========================
# 创建画布
# =========================

fig, ax1 = plt.subplots(
    figsize=(10.5, 6.5),
    dpi=220
)

# 网格
ax1.grid(True, alpha=0.25)

# =========================
# 吞吐量（蓝线）
# =========================

line1 = ax1.plot(
    tau,
    throughput,
    linewidth=2.7,
    marker='o',
    markersize=5,
    label='吞吐量'
)

ax1.set_xlabel(
    r'$\tau$',
    fontsize=24
)

ax1.set_ylabel(
    '吞吐量 (tokens/s)',
    fontsize=22,
    fontproperties=my_font
)

ax1.tick_params(
    axis='y'
)

ax1.set_xlim(1, 31)
ax1.set_ylim(28000, 70000)

# =========================
# Loss（红线）
# =========================

ax2 = ax1.twinx()

line2 = ax2.plot(
    tau[tau.index % 4 == 0],
    loss,
    color='#ff7f0e',
    linewidth=2.5,
    marker='s',
    markersize=5,
    label='最终训练 Loss'
)

ax2.set_ylabel(
    '最终训练 Loss',
    fontsize=22,
    # color='#ff7f0e',
    fontproperties=my_font
)

ax2.tick_params(
    axis='y',
    labelcolor='#ff7f0e'
)

ax2.set_ylim(2.78, 2.88)

# =========================
# 图例
# =========================

lines = line1 + line2
labels = [l.get_label() for l in lines]

legend = ax1.legend(
    lines,
    labels,
    fontsize=22,
    frameon=True,
    fancybox=True,
    framealpha=0.95,
    loc='lower right',
    prop=my_font
)

# =========================
# 边框透明度
# =========================

for spine in ax1.spines.values():
    spine.set_alpha(0.25)

for spine in ax2.spines.values():
    spine.set_alpha(0.25)

plt.tight_layout()

# =========================
# 保存图片
# =========================

plt.savefig(
    "./image/ch5_polar_tau_sensitivity.svg",
    bbox_inches='tight'
)

plt.show()