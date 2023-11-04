<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue'
import axios, { type AxiosInstance } from 'axios'

class Storage {
  readonly keyPrefix = "localai-ui:"
  readonly addressKey = "address"
  readonly currentModelIdKey = "currentModelId"

  public saveAddress(address: string) {
    localStorage.setItem(this.key(this.addressKey), address)
  }

  public getAddress(): string | null {
    return localStorage.getItem(this.key(this.addressKey))
  }

  public saveCurrentModelId(address: string) {
    localStorage.setItem(this.key(this.currentModelIdKey), address)
  }

  public getModelId(): string | null {
    return localStorage.getItem(this.key(this.currentModelIdKey))
  }

  key(name: string) {
    return `${this.keyPrefix}:${name}`
  }
}

type Model = {
  id: string
}

const storage = new Storage()

const address = ref(storage.getAddress())
const currentModelId = ref(storage.getModelId())
const prompt = ref('')
const copyOfprompt = ref('')
const responseContent = ref('')
const inProgress = ref(false)
const availableModels = ref<Model[]>([])

class ApiClient {
  readonly client: AxiosInstance

  constructor(baseUrl: string) {
    this.client = axios.create({baseURL: baseUrl})
  }

  async get(path: string, config?: any) {
    return this.client.get(path, config)
  }

  async post(path: string, data?: any) {
    return this.client.post(path, data)
  }
}

watch(address,async (newValue) => {
  storage.saveAddress(newValue || '')
})

watch(currentModelId, async (newValue) => {
  storage.saveCurrentModelId(newValue || '')
})

const loadModels = async () => {
  try {
    const { data } = await new ApiClient(address.value!).get(`/models`)
    availableModels.value = data.data
    const currentModel = availableModels.value.find(model => model.id == currentModelId.value)
    if(currentModel) {
      currentModelId.value = currentModel.id
    } else if (availableModels.value.length) {
      currentModelId.value = availableModels.value[0].id
    }
  } catch (error: any) {
    availableModels.value = []
    currentModelId.value = ""

    alert(`fail to load models: ${error.message}`)
    throw error
  }
}

onMounted(async () => {
  if (address.value) {
    await loadModels()
  }
})

const refreshModels = loadModels

const buttonEnabled = computed(() => {
  return currentModelId.value && address.value && prompt.value && !inProgress.value
})

const onSubmit = async () => {
  inProgress.value = true
  copyOfprompt.value = prompt.value
  responseContent.value = ''

  const { data } = await new ApiClient(address.value!).post(`/v1/chat/completions`, {
    model: currentModelId.value,
    messages: [{ role: 'user', content: prompt.value }],
    temperature: 0.8
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
              <input
                class="input"
                type="text"
                placeholder="address"
                v-model="address"
                v-on:blur="refreshModels"
              />
            </div>
          </div>

          <div class="field">
            <div class="label">Model</div>
            <div class="control">
              <div class="select">
                <select v-model="currentModelId">
                  <option v-for="item in availableModels" v-bind:key="item.id">
                    {{ item.id }}
                  </option>
                </select>
              </div>
            </div>
          </div>

          <div class="field">
            <div class="label">Prompt</div>
            <div class="control">
              <textarea class="textarea" v-model.trim="prompt" rows="20"></textarea>
            </div>
          </div>

          <div class="field is-grouped">
            <div class="control">
              <button class="button is-link" @click="onSubmit" :disabled="!buttonEnabled">
                Submit
              </button>
            </div>
          </div>
        </div>
        <div class="column">
          <div class="block response" v-if="responseContent">
            <b>{{ copyOfprompt }}</b
            >{{ responseContent }}
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
