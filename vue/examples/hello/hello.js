// Vue 3 冒烟用例：证明镜像里的 vue 三件套都能 require 到，且 SSR 输出确定。
//
// 用 require 而不是 import：全局安装的包靠 NODE_PATH 才能找到，
// 而 NODE_PATH 只对 CommonJS 生效，ESM 不认它。
const { createSSRApp } = require('vue');
const { parse } = require('@vue/compiler-sfc');
const { renderToString } = require('@vue/server-renderer');

const App = {
  template: '<p>hello {{ who }}</p>',
  data() {
    return { who: 'devbox' };
  },
};

// 先证明 SFC 编译器在（镜像里装了 @vue/compiler-sfc，后续用例要用它编 .vue）
console.log('compiler-sfc: ' + (typeof parse === 'function' ? 'ok' : 'missing'));

// renderToString 是异步的，但输出是确定的 HTML 字符串 —— 这正是选 SSR 而不是
// vite 打包的原因：vite 的产物文件名带内容 hash，expected.txt 没法固定。
renderToString(createSSRApp(App)).then((html) => {
  console.log(html);
});
