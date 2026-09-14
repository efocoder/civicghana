import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "civicroute.accessibility.v1"
const DEFAULTS = Object.freeze({
  textSize: "normal",
  highContrast: false,
  enhancedFocus: false,
  underlineLinks: false,
  increasedSpacing: false,
  reduceMotion: false
})
const TEXT_SIZES = ["normal", "large", "extra-large"]
const SPEECH_CHUNK_LENGTH = 420
const FEMALE_VOICE_NAMES = /female|woman|samantha|victoria|karen|moira|tessa|fiona|susan|zira|aria|jenny|sonia|ava|allison|siri|audrey|am[eé]lie|marie|hortense|denise/i
const MALE_VOICE_NAMES = /male|man|daniel|david|mark|george|thomas|guy|ryan/i

export default class extends Controller {
  static targets = ["button", "panel", "textSize", "highContrast", "enhancedFocus", "underlineLinks", "increasedSpacing", "reduceMotion", "listen", "pause", "stop", "status"]
  static values = {
    listeningLabel: String,
    pausedLabel: String,
    listenLabel: String,
    pauseLabel: String,
    resumeLabel: String,
    stoppedLabel: String,
    resetLabel: String,
    unavailableLabel: String
  }

  connect() {
    this.settings = this.loadSettings()
    this.applySettings()
    this.syncControls()
    this.previouslyFocused = null
    this.speaking = false
    this.paused = false
    this.speechSession = 0
    this.availableVoices = this.speechAvailable ? window.speechSynthesis.getVoices() : []
    this.boundVoicesChanged = () => { this.availableVoices = window.speechSynthesis.getVoices() }
    if (this.speechAvailable) window.speechSynthesis.addEventListener?.("voiceschanged", this.boundVoicesChanged)
    this.boundBeforeCache = () => this.stopSpeech(false)
    document.addEventListener("turbo:before-cache", this.boundBeforeCache)
    document.addEventListener("turbo:before-visit", this.boundBeforeCache)
    window.addEventListener("pagehide", this.boundBeforeCache)

    if (!this.speechAvailable) {
      this.listenTarget.disabled = true
      this.listenTarget.setAttribute("aria-describedby", this.statusTarget.id)
      this.setStatus(this.unavailableLabelValue)
    }
  }

  disconnect() {
    document.removeEventListener("turbo:before-cache", this.boundBeforeCache)
    document.removeEventListener("turbo:before-visit", this.boundBeforeCache)
    window.removeEventListener("pagehide", this.boundBeforeCache)
    if (this.speechAvailable) window.speechSynthesis.removeEventListener?.("voiceschanged", this.boundVoicesChanged)
    this.stopSpeech(false)
  }

  togglePanel() {
    this.panelTarget.hidden ? this.openPanel() : this.closePanel()
  }

  openPanel() {
    this.previouslyFocused = document.activeElement
    this.panelTarget.hidden = false
    this.buttonTarget.setAttribute("aria-expanded", "true")
    document.body.classList.add("accessibility-panel-open")
    requestAnimationFrame(() => this.firstFocusable?.focus())
  }

  closePanel() {
    if (this.panelTarget.hidden) return
    this.panelTarget.hidden = true
    this.buttonTarget.setAttribute("aria-expanded", "false")
    document.body.classList.remove("accessibility-panel-open")
    if (this.previouslyFocused?.isConnected) this.previouslyFocused.focus()
  }

  closeFromBackdrop(event) {
    if (event.target === this.panelTarget) this.closePanel()
  }

  handleKeydown(event) {
    if (this.panelTarget.hidden) return
    if (event.key === "Escape") {
      event.preventDefault()
      this.closePanel()
      return
    }
    if (event.key !== "Tab") return

    const focusable = this.focusableElements
    if (focusable.length === 0) return
    const first = focusable[0]
    const last = focusable[focusable.length - 1]
    if (event.shiftKey && document.activeElement === first) {
      event.preventDefault()
      last.focus()
    } else if (!event.shiftKey && document.activeElement === last) {
      event.preventDefault()
      first.focus()
    }
  }

  changeTextSize(event) {
    this.update({ textSize: TEXT_SIZES.includes(event.target.value) ? event.target.value : DEFAULTS.textSize })
  }

  changeToggle(event) {
    const setting = event.currentTarget.dataset.accessibilitySetting
    if (!Object.prototype.hasOwnProperty.call(DEFAULTS, setting) || setting === "textSize") return
    this.update({ [setting]: event.currentTarget.checked === true })
  }

  reset() {
    this.settings = { ...DEFAULTS }
    this.applySettings()
    this.syncControls()
    this.persist()
    this.setStatus(this.resetLabelValue)
  }

  async listen() {
    if (!this.speechAvailable) {
      this.setStatus(this.unavailableLabelValue)
      return
    }

    const content = this.readableText
    if (!content) return
    this.stopSpeech(false)
    const session = this.speechSession + 1
    this.speechSession = session
    this.listenTarget.disabled = true
    await this.loadVoices()
    if (session !== this.speechSession || !this.element.isConnected) return

    this.speechChunks = this.splitIntoSpeechChunks(content)
    this.speechChunkIndex = 0
    this.speaking = true
    this.paused = false
    this.listenTarget.disabled = false
    this.syncSpeechControls()
    this.setStatus(this.listeningLabelValue)
    this.speakNextChunk(session)
  }

  pauseOrResume() {
    if (!this.speechAvailable || !this.speaking) return
    if (this.paused) {
      window.speechSynthesis.resume()
      this.paused = false
      this.setStatus(this.listeningLabelValue)
    } else {
      window.speechSynthesis.pause()
      this.paused = true
      this.setStatus(this.pausedLabelValue)
    }
    this.syncSpeechControls()
  }

  stop() {
    this.stopSpeech(true)
  }

  update(change) {
    this.settings = { ...this.settings, ...change }
    this.applySettings()
    this.persist()
  }

  applySettings() {
    const root = document.documentElement
    root.dataset.accessibilityTextSize = this.settings.textSize
    root.dataset.accessibilityHighContrast = String(this.settings.highContrast)
    root.dataset.accessibilityEnhancedFocus = String(this.settings.enhancedFocus)
    root.dataset.accessibilityUnderlineLinks = String(this.settings.underlineLinks)
    root.dataset.accessibilitySpacing = this.settings.increasedSpacing ? "increased" : "normal"
    root.dataset.accessibilityReduceMotion = String(this.settings.reduceMotion)
  }

  syncControls() {
    this.textSizeTargets.forEach((control) => { control.checked = control.value === this.settings.textSize })
    this.highContrastTarget.checked = this.settings.highContrast
    this.enhancedFocusTarget.checked = this.settings.enhancedFocus
    this.underlineLinksTarget.checked = this.settings.underlineLinks
    this.increasedSpacingTarget.checked = this.settings.increasedSpacing
    this.reduceMotionTarget.checked = this.settings.reduceMotion
    this.syncSpeechControls()
  }

  loadSettings() {
    try {
      const stored = window.localStorage?.getItem(STORAGE_KEY)
      if (!stored) return { ...DEFAULTS }
      const parsed = JSON.parse(stored)
      if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) return { ...DEFAULTS }
      return {
        textSize: TEXT_SIZES.includes(parsed.textSize) ? parsed.textSize : DEFAULTS.textSize,
        highContrast: parsed.highContrast === true,
        enhancedFocus: parsed.enhancedFocus === true,
        underlineLinks: parsed.underlineLinks === true,
        increasedSpacing: parsed.increasedSpacing === true,
        reduceMotion: parsed.reduceMotion === true
      }
    } catch (_) {
      return { ...DEFAULTS }
    }
  }

  persist() {
    try {
      window.localStorage?.setItem(STORAGE_KEY, JSON.stringify(this.settings))
    } catch (_) {
      // Preferences remain active for this page when storage is unavailable.
    }
  }

  get readableText() {
    const source = document.querySelector("[data-read-aloud-content]") || document.getElementById("main-content")
    if (!source) return ""
    const copy = source.cloneNode(true)
    copy.querySelectorAll("nav, form, button, script, style, .hidden, .breadcrumbs, [hidden], [aria-hidden='true'], [data-read-aloud-exclude]").forEach((node) => node.remove())
    return copy.textContent.replace(/\s+/g, " ").trim()
  }

  get speechAvailable() {
    return Boolean(window.speechSynthesis && window.SpeechSynthesisUtterance)
  }

  get speechLanguage() {
    return { fr: "fr-FR", en: "en-GH" }[document.documentElement.lang] || document.documentElement.lang || "en-GH"
  }

  preferredVoice(language) {
    const voices = this.availableVoices?.length ? this.availableVoices : (window.speechSynthesis.getVoices?.() || [])
    const requested = language.toLowerCase()
    const base = requested.split("-")[0]
    const matching = voices.filter((voice) => voice.lang.toLowerCase().split("-")[0] === base)
    if (matching.length === 0) return null

    return matching.sort((left, right) => this.voiceScore(right, requested) - this.voiceScore(left, requested))[0]
  }

  voiceScore(voice, requestedLanguage) {
    const name = voice.name.toLowerCase()
    let score = voice.lang.toLowerCase() === requestedLanguage ? 20 : 0
    if (FEMALE_VOICE_NAMES.test(name)) score += 40
    if (MALE_VOICE_NAMES.test(name)) score -= 30
    if (/natural|premium|enhanced|neural/.test(name)) score += 10
    if (/google|microsoft|apple|serena/.test(name)) score += 4
    if (voice.localService) score += 2
    return score
  }

  loadVoices() {
    this.availableVoices = window.speechSynthesis.getVoices?.() || []
    if (this.availableVoices.length > 0) return Promise.resolve()

    return new Promise((resolve) => {
      let settled = false
      const finish = () => {
        if (settled) return
        settled = true
        window.speechSynthesis.removeEventListener?.("voiceschanged", finish)
        this.availableVoices = window.speechSynthesis.getVoices?.() || []
        resolve()
      }
      window.speechSynthesis.addEventListener?.("voiceschanged", finish, { once: true })
      window.setTimeout(finish, 500)
    })
  }

  splitIntoSpeechChunks(text) {
    const sentences = this.sentencesFor(text)
    const chunks = []
    let current = ""

    sentences.flatMap((sentence) => this.splitLongSentence(sentence)).forEach((sentence) => {
      const candidate = current ? `${current} ${sentence}` : sentence
      if (candidate.length <= SPEECH_CHUNK_LENGTH) {
        current = candidate
      } else {
        if (current) chunks.push(current)
        current = sentence
      }
    })
    if (current) chunks.push(current)
    return chunks
  }

  sentencesFor(text) {
    if (window.Intl?.Segmenter) {
      const segmenter = new Intl.Segmenter(document.documentElement.lang || "en", { granularity: "sentence" })
      return Array.from(segmenter.segment(text), ({ segment }) => segment.trim()).filter(Boolean)
    }
    return text.match(/[^.!?]+[.!?]+|[^.!?]+$/g)?.map((sentence) => sentence.trim()).filter(Boolean) || []
  }

  splitLongSentence(sentence) {
    if (sentence.length <= SPEECH_CHUNK_LENGTH) return [sentence]
    const chunks = []
    let current = ""
    sentence.split(/\s+/).forEach((word) => {
      const candidate = current ? `${current} ${word}` : word
      if (candidate.length <= SPEECH_CHUNK_LENGTH) {
        current = candidate
      } else {
        if (current) chunks.push(current)
        current = word
      }
    })
    if (current) chunks.push(current)
    return chunks
  }

  speakNextChunk(session) {
    if (!this.speaking || session !== this.speechSession) return
    const text = this.speechChunks[this.speechChunkIndex]
    if (!text) {
      this.finishSpeech()
      return
    }

    const utterance = new SpeechSynthesisUtterance(text)
    utterance.lang = this.speechLanguage
    utterance.rate = 0.92
    utterance.pitch = 1
    utterance.volume = 1
    const voice = this.preferredVoice(utterance.lang)
    if (voice) utterance.voice = voice
    utterance.onend = () => {
      if (session !== this.speechSession) return
      this.speechChunkIndex += 1
      this.speakNextChunk(session)
    }
    utterance.onerror = (event) => {
      if (session !== this.speechSession || event.error === "canceled" || event.error === "interrupted") return
      this.finishSpeech()
    }
    this.utterance = utterance
    window.speechSynthesis.speak(utterance)
  }

  stopSpeech(announce) {
    this.speechSession = (this.speechSession || 0) + 1
    if (this.speechAvailable) window.speechSynthesis.cancel()
    this.utterance = null
    this.speechChunks = []
    this.speechChunkIndex = 0
    this.speaking = false
    this.paused = false
    if (this.hasListenTarget) this.listenTarget.disabled = !this.speechAvailable
    this.syncSpeechControls()
    if (announce) this.setStatus(this.stoppedLabelValue)
  }

  finishSpeech() {
    this.utterance = null
    this.speaking = false
    this.paused = false
    this.syncSpeechControls()
    this.setStatus("")
  }

  syncSpeechControls() {
    if (!this.hasPauseTarget || !this.hasStopTarget || !this.hasListenTarget) return
    this.listenTarget.textContent = this.listenLabelValue
    this.pauseTarget.hidden = !this.speaking
    this.stopTarget.hidden = !this.speaking
    this.pauseTarget.textContent = this.paused ? this.resumeLabelValue : this.pauseLabelValue
  }

  setStatus(message) {
    if (this.hasStatusTarget) this.statusTarget.textContent = message
  }

  get focusableElements() {
    return Array.from(this.panelTarget.querySelectorAll("button:not([disabled]):not([hidden]), input:not([disabled]), select:not([disabled]), [href], [tabindex]:not([tabindex='-1'])"))
      .filter((element) => !element.closest("[hidden]"))
  }

  get firstFocusable() {
    return this.focusableElements[0]
  }
}
