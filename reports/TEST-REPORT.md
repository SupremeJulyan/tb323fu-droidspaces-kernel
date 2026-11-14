# 编译与验证记录（2026-11-14）

## 结论

目前产物仅供研究，不可认定适合刷入 TB323FU。容器功能在 ARM64 QEMU 中运行通过，但完整原厂驱动兼容性门槛未通过，也没有平板硬件测试结果。

## 方法

- 从实际设备导出配置，固定原厂源码提交、Android Clang、Rust 和 bindgen 版本。
- 原厂基线保持 Rust Binder、CFI、MODVERSIONS、GENDWARFKSYMS 和 BTF。
- 容器版本应用上游 IPC 布局补丁，启用 PID/IPC/user namespace、SYSVIPC、POSIX_MQUEUE、DEVTMPFS，并补充 Rust Binder 所需的两个 GPL 符号导出。
- 使用 Android gendwarfksyms stable 模式；用 pahole 1.32 解决 1.25 的 per-CPU 变量上限。
- QEMU 8.2.2、ARM64 virt/max、2 vCPU、1 GiB RAM，使用独立的无 libc initramfs 测试程序；不挂载设备数据或宿主个人文件。

## 功能测试

原厂基线正常启动，PID/IPC、SYSVIPC、消息队列、devtmpfs、user namespace 按预期失败，说明检测能够识别真实缺失项。

容器版本正常启动并关机，下列 18 项全部通过：procfs、sysfs、devtmpfs、mount namespace、UTS namespace、IPC namespace、network namespace、SysV shared memory 创建/映射/读写、SysV semaphore、POSIX 消息队列创建/发送/接收、cgroup2 mount、PID namespace 中 PID 1、user namespace、seccomp filter。对应日志见 container-qemu.log。

这些测试不是完整 Droidspaces 发行版、Docker 或 GPU 测试，也不能证明触控、Wi-Fi、声音、休眠与 Android 框架能正常工作。

## 原厂驱动样本

实际设备 ADSP 模块的 37 个 GKI 导入 CRC 与 stable 模式下的原厂基线一致；`spf_core_is_apm_ready` 来自其他厂商模块，尚未检查。完整驱动导出期间 ADB 断开，未取得全部厂商模块，不能推广为所有模块已通过。

容器版本的全导出表对比存在 23 个 Rust 相关导出 CRC 变化和 3 个缺失项，见 abi-comparison.json。即使原厂样本匹配，也不能据此忽略原厂 Rust 模块的不兼容风险。

Image 的 ARM64/4K 头部检查通过；task_struct 总大小均为 5184 字节，检查的关键公共字段偏移和大小一致，见 artifact-inspection.json。结构布局检查通过不能替代全导出表检查。最终 ABI 检查退出码为 1，布局检查退出码为 0。

两套 Image、vmlinux 和 Module.symvers 保存在本地 artifacts/2026-11-14，校验值见 artifact-sha256.txt。未打包成可刷入的 boot.img。实际构建内核版本串见 *-kernel-release.txt；这是直接 make 的研究构建，不是原厂二进制复现。

## Droidspaces LKM 备选路线

检查项目：https://github.com/misaka5202/droidspaces-lkm

实际下载并测试 v1.0 的 droidspaces-lkm-android16-6.12-arm64.zip；包哈希见 lkm-package-sha256.txt。项目方案通过加载内核模块补入能力，不需要刷写 boot.img；这仍是在内核态运行代码。

- 预编译模块 vermagic 为 6.12.76-4k，与本机 6.12.30 不同。
- 模块有空的 `__versions` 段，没有可用于比较的导入符号 CRC 条目。
- 对当前基线静态检查，lkm4ctr 引用 8 个未导出符号。
- 在原厂基线 QEMU 中实际加载：lkm4ctr 由于 Unknown symbol 失败；devtmpfs_lkm 使用 devtmpfs_probe=2 能加载且 mount 成功，伴有 BTF 不匹配信息。
- PID、IPC、消息队列仍失败，不能视为当前包已适配。详见 baseline-lkm-qemu.log 和 lkm-static-check.json。

没有把 LKM 包安装到平板，也没有设置开机自加载。

## 尚需完成的设备准入条件

解决 Rust 导出接口兼容性；核对全部实际厂商及 system_dlkm 模块；重新验证当前启动分区备份和恢复路径；再安排独立的平板测试。当前阶段未刷写任何设备分区。
