# 原厂基线核查（2026-11-14）

`stock.config.gz` 从在线设备 `/proc/config.gz` 只读导出，`stock.config` 为解压版本。不包含用户文件或设备序列号。

通过 `/proc/version` 获取 Clang 版本和构建编号，通过 Android Gitiles 查询确认短提交对应的完整源码提交。固定版本见 source-lock.json。

源码：https://android.googlesource.com/kernel/common/+/1750f757fabea014ecc59d327c0c9d3c15ab1e6d

## 编译环境

电脑已有 Ubuntu 24.04 WSL2，x86_64，分配约 7.6 GiB 内存、2 GiB swap。已取得与原厂版本文本完全一致的 Android Clang 和 Rust，以及 bindgen 0.69.5。WSL 显示的虚拟磁盘可用空间不是宿主盘实际可用空间。

## 尚待完成

- 当前使用直接 make 构建及从源码重建的符号/受保护模块清单，不宣称已复现完整 Kleaf 构建环境。
- Ubuntu pahole 1.25 达到 per-CPU 变量上限，导致 BTF 链接失败；改用从 acmel/dwarves 源码编译的 pahole 1.32，保留 BTF 配置。
- 必须启用 `KBUILD_GENDWARFKSYMS_STABLE=1`。在普通模式下生成过对象后，切换此环境变量不会自动使 Kbuild 重编译，需刷新缓存中的 CRC 元数据；仓库脚本会执行该步骤。
- 原厂 ADSP 模块样本的 37 个 GKI 导入 CRC 与修正后的基线一致；另一个厂商模块提供的 `spf_core_is_apm_ready` 未解析。设备连接中断，尚未完成全部模块导出。
- 完整硬件兼容性与回刷流程仍未验证。测试状态见 reports。

不得以相同 KMI 或源码版本号代替实际驱动兼容性验证。本阶段未写入设备分区。
