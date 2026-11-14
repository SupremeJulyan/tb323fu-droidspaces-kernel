# 原厂基线核查（2026-11-14）

`stock.config.gz` 从在线设备 `/proc/config.gz` 只读导出，`stock.config` 为解压版本。不包含用户文件或设备序列号。

通过 `/proc/version` 获取 Clang 版本和构建编号，通过 Android Gitiles 查询确认短提交对应的完整源码提交。固定版本见 source-lock.json。

源码：https://android.googlesource.com/kernel/common/+/1750f757fabea014ecc59d327c0c9d3c15ab1e6d

## 编译环境

电脑已有 Ubuntu 24.04 WSL2，x86_64，分配约 7.6 GiB 内存、2 GiB swap；尚未发现 clang。WSL 显示的虚拟磁盘可用空间不是宿主盘实际可用空间，下载前需核对宿主磁盘。

## 尚待完成

- 获取匹配构建的 manifest、Kleaf 和精确工具链。
- 获取原厂模块符号版本信息，建立 ABI 比对基线。
- 固定 Droidspaces 补丁提交并检查其对本源码的适用性。
- 先构建原厂基线，再进行容器配置修改。

不得以相同 KMI 或源码版本号代替实际驱动兼容性验证。本阶段未写入设备分区。
