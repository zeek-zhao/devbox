<template>
  <li
    class="todo-item"
    :class="{ completed: todo.completed }"
    :aria-label="todo.text + ', ' + remaining + ' remaining'"
  >
    <label>
      <input type="checkbox" :checked="todo.completed" @change="$emit('toggle', todo.id)" />
      <span>{{ todo.text }}</span>
    </label>
    <button type="button" @click="$emit('remove', todo.id)">Remove</button>
  </li>
</template>

<!-- L1-014-class-style-binding: the completed class follows todo.completed. -->
