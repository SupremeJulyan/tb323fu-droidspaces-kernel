# 上游候选补丁

- 来源：ravindu644/Droidspaces-OSS
- 固定提交：`cdadb9eb5d0f86aacffff60776333e6f6b73a30a`
- 原始路径：`Documentation/resources/kernel-patches/GKI/kernel-6.12/001.GKI-6.12-or-above-fix_sysvipc_kabi.patch`
- 链接：https://github.com/ravindu644/Droidspaces-OSS/blob/cdadb9eb5d0f86aacffff60776333e6f6b73a30a/Documentation/resources/kernel-patches/GKI/kernel-6.12/001.GKI-6.12-or-above-fix_sysvipc_kabi.patch

原样保存作审核，不代表已适用于本设备。初步阅读发现其将 task_struct 的 SysV IPC 字段移动到 packed union；必须检查原厂配置下结构布局、对齐及模块符号 CRC，不能仅凭补丁名称认定 ABI 安全。

使用和分发需遵守上游适用许可证；此处保留来源，不主张原创。应用和编译进展见下文及测试报告。

## 本地补充补丁

`002-export-ipc-for-rust-binder.patch`：启用 IPC namespace 后，原厂配置中的模块化 Rust Binder 引用了 `init_ipc_ns` 和 `put_ipc_ns`，但原源码未导出这两个符号，导致 modpost 失败。本补丁增加 GPL 导出，并在容器构建的符号保留清单中加入它们；没有关闭 Rust Binder、CFI 或符号版本校验。

上游候选补丁已通过精确源码的应用检查；最终构建与 ABI 检查状态以 reports 中的测试报告为准。
