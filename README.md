# TB323FU Droidspaces Kernel

联想拯救者 Y700 五代（TB323FU）Android 内核容器功能适配研究。

当前阶段：收集基线、检查 GKI ABI 兼容性；尚无经过验证的可刷入内核。仓库内容不代表设备兼容性保证。

## 设备基线

- 型号：TB323FU，PRC。
- 系统：Android 16，ZUXOS 2.0.12.088。
- 内核：`6.12.30-android16-5-g1750f757fabe-ab13938768-4k`。
- KMI：`android16-6.12`；页大小：4 KiB。
- 已读取配置：PID_NS、SYSVIPC、POSIX_MQUEUE、DEVTMPFS、USER_NS 未开启。

## 适配顺序

1. 固定与原厂匹配的源码提交、工具链和配置，检查原厂模块的 ABI 要求。
2. 审核 Droidspaces 的 6.12 GKI ABI 补丁，启用必要的容器功能。
3. 编译并检查产物、配置和模块接口。
4. 在完成恢复准备后另行安排设备测试。

TB322FC 四代的 6.6 内核二进制不能直接用于本设备；其项目仅作实现参考。

## 已有恢复材料

本地已保存原始非 userdata 分区、六个 LUN 的主备 GPT 和配套 loader。
2026-11-14 重新检查：140 个镜像文件、40 个 GPT 相关文件、8 个 loader 文件均通过历史 SHA-256 校验；正式分区中仅 userdata 未备份，其余大小与本机清单相符。

未实际测试恢复，不保证回刷成功。刷入前仍需补存当前启动分区，并备份重要个人文件。
设备镜像、密钥、用户数据及设备唯一信息不得提交到本仓库。

## 参考

- https://www.droidspaces.org/docs/kernel-configuration.html
- https://github.com/ll1zt/tb322fc-droidspaces-kernel
- https://github.com/midori01/gki_ksu_workflow
- https://github.com/joonhoekim/tb323fu-linux

