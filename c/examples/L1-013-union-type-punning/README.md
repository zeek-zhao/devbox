<!-- coverage: pending -->

# L1-013 —— union 与类型双关

将 `uint32_t` 写入 union 后读取字节数组，以观察当前平台的字节序。通过非当前成员
读取 union 在 ISO C 中是实现定义行为；输出只描述此工具链，不可当作跨平台保证。
