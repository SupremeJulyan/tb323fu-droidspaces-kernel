# 上游候选补丁

- 来源：ravindu644/Droidspaces-OSS
- 固定提交：`cdadb9eb5d0f86aacffff60776333e6f6b73a30a`
- 原始路径：`Documentation/resources/kernel-patches/GKI/kernel-6.12/001.GKI-6.12-or-above-fix_sysvipc_kabi.patch`
- 链接：https://github.com/ravindu644/Droidspaces-OSS/blob/cdadb9eb5d0f86aacffff60776333e6f6b73a30a/Documentation/resources/kernel-patches/GKI/kernel-6.12/001.GKI-6.12-or-above-fix_sysvipc_kabi.patch

原样保存作审核，不代表已适用于本设备。初步阅读发现其将 task_struct 的 SysV IPC 字段移动到 packed union；必须检查原厂配置下结构布局、对齐及模块符号 CRC，不能仅凭补丁名称认定 ABI 安全。

尚未应用或编译。后续获取源码后先执行 apply check，并做基线与修改后结构布局比较。使用和分发需遵守上游适用许可证；此处保留来源，不主张原创。
