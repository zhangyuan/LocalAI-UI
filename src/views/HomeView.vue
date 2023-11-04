<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue'
import axios from 'axios';

type Model = {
  id: string
}

const address = ref("http://localhost:8080")
const currentModel = ref("")
const prompt = ref("")
const copyOfprompt = ref("")
const responseContent = ref("")
const inProgress = ref(false)
const availableModels = ref<Model[]>([])

const apiClient = axios.create({});

const loadModels = async() => {
  try {
    const { data } = await apiClient.get(`${address.value}/models`)
    availableModels.value = data.data
    currentModel.value = ""
    if (!currentModel.value && availableModels.value.length > 0) {
      currentModel.value = availableModels.value[0].id
    }
  } catch(error: any) {
    console.error(error.message)
    availableModels.value = []
    alert(`fail to load models: ${error.message}`)
    throw error
  }
}

onMounted(async() => {
  await loadModels()
})

const refreshModels = loadModels

const buttonEnabled = computed(() => {
  return currentModel.value && address.value && prompt.value && !inProgress.value;
})

const onSubmit = async () => {
  inProgress.value = true
  copyOfprompt.value = prompt.value
  responseContent.value = ""

  const { data } = await apiClient.post(`${address.value}/v1/chat/completions`, {
     "model": currentModel.value,
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
              <input class="input" type="text" placeholder="address" v-model="address" v-on:blur="refreshModels">
            </div>
          </div>

          <div class="field">
            <div class="label">Model</div>
            <div class="control">
              <div class="select">
                <select v-model="currentModel">
                  <option v-for="item in availableModels" v-bind:key="item.id">{{  item.id }}</option>
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
