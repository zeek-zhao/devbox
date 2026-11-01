<template>
  <li
    class="todo-item"
    :class="{ completed: todo.completed }"
    :aria-label="todo.text + ', ' + remaining + ' remaining'"
  >
    <label>
      <input type="checkbox" :checked="todo.completed" @change="$emit('toggle', todo.id)" />
      <!-- L1-028-vhtml-escape: text interpolation escapes todo content instead of treating it as HTML. -->
      <span>[[ todo.text ]]</span>
    </label>
    <button type="button" @click="$emit('remove', todo.id)">Remove</button>
    <button type="button" :disabled="position === 0" @click="$emit('move-up', todo.id)">
      Move up
    </button>
  </li>
</template>

<!-- L1-014-class-style-binding: the completed class follows todo.completed. -->
