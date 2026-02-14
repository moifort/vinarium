<script setup lang="ts">
const { data, refresh } = await useFetch('/api/hello')
</script>

<template>
	<h1 class="text-3xl font-bold underline">
		{{ data?.message }}
	</h1>
  <UButton @click="() => refresh()">Button</UButton>
</template>
