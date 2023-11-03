<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue'
import axios from 'axios';

const address = ref("http://localhost:8080")
const model = ref("baichuan-vicuna-7b.ggmlv3.q4_0.bin")
const prompt = ref("")
const copyOfprompt = ref("")
const responseContent = ref("")
const inProgress = ref(false)
const models = ref([])

const loadModels = async() => {
  const { data } = await axios.get(`${address.value}/models`)
  models.value = data.data
}

onMounted(async() => {
  await loadModels()
})

watch(address, async() => {
  await loadModels()
})

const buttonEnabled = computed(() => {
  return model.value && address.value && prompt.value && !inProgress.value;
})

const onSubmit = async () => {
  inProgress.value = true
  copyOfprompt.value = prompt.value
  responseContent.value = ""

  const { data } = await axios.post(`${address.value}/v1/chat/completions`, {
     "model": model.value,
     "messages": [{"role": "user", "content": prompt.value}],
     "temperature": 0.8
   })

   inProgress.value = false
   responseContent.value = data.choices[0].message.content
}

</script>

<template>
  <main>
    <div class="container">
      <h1 class="title">LocalAI</h1>
      <div class="columns">
        <div class="column">
          <div class="field">
            <div class="label">LocalAI Address</div>
            <div class="control">
              <input class="input" type="text" placeholder="address" v-model="address">
            </div>
          </div>

          <div class="field">
            <div class="label">Model</div>
            <div class="control">
              <div class="select">
                <select v-model="model">
                  <option v-for="item in models" v-bind:key="item.id">{{  item.id }}</option>
                </select>
              </div>
            </div>
          </div>

          <div class="field">
            <div class="label">Prompt</div>
            <div class="control">
              <textarea class="textarea" v-model.trim="prompt"></textarea>
            </div>
          </div>

          <div class="field is-grouped">
            <div class="control">
              <button class="button is-link" @click="onSubmit" :disabled="!buttonEnabled">Submit</button>
            </div>
          </div>
        </div>
        <div class="column">
          <div class="block response" v-if="responseContent">
            <b>{{ copyOfprompt }}</b>{{  responseContent  }}
          </div>
        </div>
      </div>
    </div>

  </main>
</template>


<style scoped>
.response {
  white-space: pre-wrap;
}
</style>
