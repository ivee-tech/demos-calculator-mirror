<style lang="css">
@import "./operation.css";
</style>

<template>
  <div class="container">
    <div class="calculator">
      <div class="text-center">
        <h1 class="display-4">Calculator</h1>
        <p>Enter the expression you want to calculate.</p>
        <div id="calc" class="calc">
          <div id="expr">
            <input type="text" id="txtExpr" readonly class="txt-expr" /> =
            <input
              type="text"
              id="txtResult"
              readonly
              class="txt-result"
              v-model="operationResult.result"
            />
            <span id="spinner" v-if="operationLoading"
              ><img src="/img/spinner.gif" width="30"
            /></span>
          </div>
          <div id="buttons" class="calc-buttons">
            <div>
              <button id="7" v-on:click="r('7')" class="calc-button">7</button>
              <button id="8" v-on:click="r('8')" class="calc-button">8</button>
              <button id="9" v-on:click="r('9')" class="calc-button">9</button>
              <button id="div" v-on:click="r('/')" class="calc-button-op">
                /
              </button>
            </div>
            <div>
              <button id="4" v-on:click="r('4')" class="calc-button">4</button>
              <button id="5" v-on:click="r('5')" class="calc-button">5</button>
              <button id="6" v-on:click="r('6')" class="calc-button">6</button>
              <button id="mul" v-on:click="r('*')" class="calc-button-op">
                X
              </button>
            </div>
            <div>
              <button id="1" v-on:click="r('1')" class="calc-button">1</button>
              <button id="2" v-on:click="r('2')" class="calc-button">2</button>
              <button id="3" v-on:click="r('3')" class="calc-button">3</button>
              <button id="sub" v-on:click="r('-')" class="calc-button-op">
                -
              </button>
            </div>
            <div>
              <button id="0" v-on:click="r('0')" class="calc-button">0</button>
              <button id="dot" v-on:click="r('.')" class="calc-button">
                .
              </button>
              <button id="ob" v-on:click="r('(')" class="calc-button-small">
                (
              </button>
              <button id="cb" v-on:click="r(')')" class="calc-button-small">
                )
              </button>
              <button id="add" v-on:click="r('+')" class="calc-button-op">
                +
              </button>
            </div>
          </div>
          <div id="divResults" class="div-results">
            <button id="clr" v-on:click="clearText()" class="calc-button-small">
              C
            </button>
            <button
              id="rem"
              v-on:click="removeLastChar()"
              class="calc-button-small"
            >
              &lt;-
            </button>
            <button
              id="result"
              v-on:click="loadResult()"
              class="calc-button-result"
            >
              =
            </button>
          </div>
          <div id="error" class="error" v:if="operation.error">
            {{ operationResult.errorMessage }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import axios from "axios";
import { StoreService } from "@/services/store-service";

@Component
export default class Operation extends Vue {
  operationResult: { result: number; errorMessage: string } = {
    result: 0,
    errorMessage: "",
  };
  operationLoading: boolean = false;

  private storeSvc: StoreService = new StoreService();
  private config: any;

  constructor() {
    super();
  }

  mounted() {
    this.config = this.storeSvc.getConfig();
  }

  r(c: string) {
    const expr: any = document.getElementById("txtExpr");
    expr.value += c;
  }

  clearText() {
    const expr: any = document.getElementById("txtExpr");
    expr.value = "";
    let divError = document.getElementById("error") as HTMLDivElement;
    divError.innerText = "";
  }

  removeLastChar() {
    let expr: any = document.getElementById("txtExpr");
    if (expr.value.length >= 1) {
      let value = expr.value.substring(0, expr.value.length - 1);
      expr.value = value;
    }
  }
  toggleSpinner() {
    const spinner = document.getElementById("spinner") as HTMLSpanElement;
    if (spinner.style.display === "none") spinner.style.display = "";
    else spinner.style.display = "none";
  }

  isSpinnerHidden() {
    const spinner = document.getElementById("spinner") as HTMLSpanElement;
    return spinner.style.display === "none";
  }

  loadResult() {
    let txtExpr: any = document.getElementById("txtExpr") as HTMLInputElement;
    let expr = encodeURIComponent(txtExpr.value);
    this.operationLoading = true;
    axios
      .post(`${this.config.apiBaseUrl}/Operation/execute`, {
        expression: expr,
      })
      .then((response) => {
        console.log(response);
        this.operationResult = {
          result: response.data.result,
          errorMessage: "",
        };
        this.operationLoading = false;
      })
      .catch((error) => {
        console.log(error);
        this.operationResult = { result: 0, errorMessage: `${error.message} - ${error.response.data.detail}` };
        this.operationLoading = false;
      });
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped lang="less">
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

a {
  color: #42b983;
}
</style>
