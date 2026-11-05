// T-001-props-reactivity-env · 机制隔离实验（headless，@vue/reactivity 原语层）
// 把「解构 props 丢响应性」下沉到响应式原语层做最小隔离对照：
// 同一个 reactive 对象，effect 追踪两种读法——经代理读（props.count）vs 解构快照读（count）。
import { reactive, effect } from 'vue';

const props = reactive({ count: 1 });
const { count } = props; // 解构 = 对代理做一次属性读取，拿到的是当时的原始值
let viaProxy = '';
let viaDestructured = '';
effect(() => {
  viaProxy = String(props.count);
});
effect(() => {
  viaDestructured = String(count);
});
props.count = 2; // 触发：代理读法应重新执行，快照读法无人通知

console.log(`EFFECT proxy-read=${viaProxy} destructured-read=${viaDestructured}`);
if (viaProxy === '2' && viaDestructured === '1') {
  console.log('EFFECT-CONFIRMED: proxy read is tracked, destructured snapshot is not');
  process.exit(1); // 证据坐实 = 非零退出（docs/72 §2 纪律）
}
console.log('EFFECT-UNEXPECTED: isolation experiment did not reproduce (environment drift?)');
process.exit(2);
