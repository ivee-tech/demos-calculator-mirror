<template>
  <div id="main-div" class="main-div">

  </div>
</template>

<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";

@Component<Main>({
  data() {
    return {
    };
  },
  mounted: function () {
    this.mounted();
  },
})
export default class Main extends Vue {
  @Prop() private msg!: string;

  constructor() {
    super();
  }

  mounted() {
    console.log();
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
h3 {
  margin: 40px 0 0;
}
ul {
  list-style-type: none;
  padding: 0;
}
li {
  display: inline-block;
  margin: 0 10px;
}

.chk-editor {
  width: 40px;
  height: 40px;
}

.lbl-editor {
  font-size: 40px;
}
</style>
