# L3-009-umask-file-perms

## 考点
对应 KP-SH-L3-09：umask 从创建权限里扣掉掩码位；同一应用在 077/022 下落点分别是 600/700 与 644/755。

## 易错点
以为 umask 是「chmod 的反义」直接照抄目标权限；掩码只作用于新文件，已有文件不受影响，需要显式 chmod。

## 延伸
把密钥文件用 077 子壳创建，配置目录用 022，让权限落点成为部署清单的一部分。

## 复现
TAG=latest scripts/run-example.sh shell L3-009-umask-file-perms
