<template>
  <main class="todo-app">
    <h1>Devbox todos</h1>
    <nav aria-label="Main navigation">
      <a href="/" @click.prevent="navigate('/')">Todos</a>
      <a href="/about" @click.prevent="navigate('/about')">About</a>
    </nav>
    <section v-if="route.name === 'about'" class="about">
      <h2>About</h2>
      <p>A small server-rendered todo list.</p>
    </section>
    <section v-else>
      <form @submit.prevent="addTodo">
        <label for="new-todo">New todo</label>
        <input id="new-todo" ref="draftInput" v-model.trim="draft" autocomplete="off" />
        <button type="submit">Add</button>
      </form>
      <p class="remaining" aria-live="polite">{{ remaining }} left</p>
      <p v-show="todos.length === 0" class="empty">No todos yet.</p>
      <ul class="todo-list">
        <TodoItem
          v-for="todo in visibleTodos"
          :key="todo.id"
          :todo="todo"
          @toggle="toggleTodo"
          @remove="removeTodo"
        />
      </ul>
    </section>
    <slot name="footer">
      <small>Todo list</small>
    </slot>
  </main>
</template>

<!-- L1-007-v-model-expand: the input binds its draft with v-model. -->
<!-- L1-011-template-refs: draftInput is attached to the input for post-render focus. -->
<!-- L1-012-vif-vs-vshow: route sections use v-if while the empty state uses v-show. -->
<!-- L1-013-vfor-key: the list iterates todos with the stable todo.id key. -->
<!-- L1-015-form-modifiers: v-model.trim normalizes the submitted draft. -->
