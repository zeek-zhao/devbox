// T-001-props-reactivity-env · 生产环境变量消费点（缺陷现场之二）
// VITE_API_URL / VITE_BUILD_TAG 没有在任何 .env 文件里声明。
// vite build 会把 import.meta.env.<未声明变量> 静态替换为 undefined，
// 经压缩改写为 void 0 ——「构建成功、零告警」不等于「配置在场」。
export const API_URL = import.meta.env.VITE_API_URL;
export const BUILD_TAG = import.meta.env.VITE_BUILD_TAG;
console.log("[env] API_URL=", API_URL, "BUILD_TAG=", BUILD_TAG);
