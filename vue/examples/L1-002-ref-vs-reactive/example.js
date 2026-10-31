const { isRef, reactive, ref } = require('vue');

const count = ref(1);
count.value += 1;
const state = reactive({ x: 1 });
state.x += 2;

console.log(`ref value: ${count.value}`);
console.log(`reactive x: ${state.x}`);
console.log(`isRef(ref): ${isRef(count)}`);
console.log(`isRef(reactive): ${isRef(state)}`);
