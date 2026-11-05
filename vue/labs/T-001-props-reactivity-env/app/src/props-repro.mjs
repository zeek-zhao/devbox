// T-001-props-reactivity-env · 缺陷现场之一（headless 真跑，无 DOM 依赖）
// 用 createRenderer + 空操作 nodeOps 挂载一个真实 Vue 应用（走完整的
// 响应式追踪 -> 组件更新 -> 调度 flush 路径），对照两个子组件：
//   Bug  —— setup 里解构 props（const { count } = props），渲染闭包读的是 setup 时刻的快照；
//   Good —— 渲染闭包直读 props.count（活的响应式代理）。
// 父组件把 state.count 从 1 改到 2，判读两个组件各自渲染出的文本与渲染次数。
// 证据纪律：复现成功（丢响应性坐实）= 本脚本以退出码 1 结束（docs/72 §2）。
import { createRenderer, h, reactive, nextTick } from 'vue';

const els = {}; // 按宿主标签名收集元素，供判读文本快照
const nodeOps = {
  createElement: (tag) => {
    const el = { type: 'el', tag, children: [] };
    els[tag] = el;
    return el;
  },
  createText: (t) => ({ type: 'txt', text: t ?? '' }),
  createComment: (t) => ({ type: 'com', text: t }),
  setText: (n, t) => {
    n.text = t;
  },
  setElementText: (n, t) => {
    n.children = [t];
  },
  patchProp: () => {},
  insert: () => {},
  remove: () => {},
  nextSibling: () => null,
  parentNode: () => null,
};

const { createApp } = createRenderer(nodeOps);
const state = reactive({ count: 1 });
const renders = { Bug: 0, Good: 0 };

const Bug = {
  props: ['count'],
  setup(props) {
    const { count } = props; // 缺陷：解构 props —— count 是 setup 时刻的快照，不再被追踪
    return () => {
      renders.Bug += 1;
      return h('div', String(count));
    };
  },
};
const Good = {
  props: ['count'],
  setup(props) {
    return () => {
      renders.Good += 1;
      return h('span', String(props.count)); // 健康对照：渲染时直读响应式代理
    };
  },
};

createApp({
  setup: () => () =>
    h('section', [h(Bug, { count: state.count }), h(Good, { count: state.count })]),
}).mount({ type: 'root' });

console.log('PROPS-REPRO start (headless custom renderer, no DOM)');
console.log(
  `first  renders Bug=${renders.Bug} Good=${renders.Good} text buggy=${els.div.children[0]} good=${els.span.children[0]}`,
);

state.count = 2;
await nextTick();

console.log(
  `update renders Bug=${renders.Bug} Good=${renders.Good} text buggy=${els.div.children[0]} good=${els.span.children[0]}`,
);

const buggyAfter = els.div.children[0];
const goodAfter = els.span.children[0];
if (buggyAfter === String(state.count) && goodAfter === String(state.count)) {
  console.log('REACTIVITY-OK: both components read live props (fix-verified path)');
  process.exit(0);
}
console.log(
  `REACTIVITY-LOST: Bug re-rendered ${renders.Bug}x but its text froze at ${buggyAfter} while live props.count = ${state.count} (Good=${goodAfter})`,
);
process.exit(1);
