<template>
  <div class="home">
    <Operation />
  </div>
</template>

<script lang="ts">
import { Component, Vue } from 'vue-property-decorator';
import Main from '@/components/Main.vue'; // @ is an alias to /src
import Operation from '@/components/Operation/Operation.vue'; // @ is an alias to /src

@Component({
  components: {
    Operation,
  },
})
export default class Home extends Vue {}
</script>
