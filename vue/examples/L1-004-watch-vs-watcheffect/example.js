const { nextTick, ref, watch, watchEffect } = require('vue');

async function main() {
  const source = ref(0);
  const order = [];
  let watchRuns = 0;
  let effectRuns = 0;

  watch(source, () => {
    watchRuns += 1;
    order.push('watch');
  });
  watchEffect(() => {
    source.value;
    effectRuns += 1;
    order.push('watchEffect');
  });

  source.value += 1;
  await nextTick();

  console.log(`order: ${order.join(', ')}`);
  console.log(`watch runs: ${watchRuns}`);
  console.log(`watchEffect runs: ${effectRuns}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
