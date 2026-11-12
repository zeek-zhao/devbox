# L2-019-manifest-install-uninstall

## 考点
对应 KP-SH-L2-19：安装/卸载以清单为准，卸载只移除清单内条目，清单外内容保持原样。

## 易错点
用通配清理（rm -rf 目录下全部）会波及清单外文件；卸载循环以同一份清单为唯一事实来源。

## 延伸
把清单机制接入部署：版本化 manifest，卸载支持按版本回退清单执行。

## 复现
TAG=latest scripts/run-example.sh shell L2-019-manifest-install-uninstall
