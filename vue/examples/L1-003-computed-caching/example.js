const { computed, ref } = require('vue');

const count = ref(2);
let getterRuns = 0;
const doubled = computed(() => {
  getterRuns += 1;
  return count.value * 2;
});

const values = [doubled.value, doubled.value, doubled.value];
console.log(`values: ${values.join(', ')}`);
console.log(`getter runs: ${getterRuns}`);
