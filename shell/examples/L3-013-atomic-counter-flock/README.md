# L3-013-atomic-counter-flock

## 考点
对应 KP-SH-L3-13：读-改-写放进 flock 文件锁的临界区，两个并发进程各 20 次后计数精确到 40。

## 易错点
把锁加在计数文件本身锁不住竞态窗口；锁必须是所有写者共识的同一把，fd 级锁在子壳里要显式打开。

## 延伸
把锁模式接入部署：多实例部署器用同一把锁排队执行变更。

## 复现
TAG=latest scripts/run-example.sh shell L3-013-atomic-counter-flock
