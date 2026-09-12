import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["text", "button"]

  connect() {
    if (!("speechSynthesis" in window)) this.buttonTarget.hidden = true
  }

  speak() {
    if (!("speechSynthesis" in window)) return

    window.speechSynthesis.cancel()

    const utterance = new SpeechSynthesisUtterance(this.textTarget.textContent.trim())
    const locale = document.documentElement.lang
    utterance.lang = { fr: "fr-FR" }[locale] || "en-GH"
    utterance.rate = 0.9

    this.buttonTarget.textContent = "Listening..."
    utterance.onend = () => { this.buttonTarget.textContent = "Listen" }
    utterance.onerror = () => { this.buttonTarget.textContent = "Listen" }

    window.speechSynthesis.speak(utterance)
  }

  disconnect() {
    if ("speechSynthesis" in window) {
      window.speechSynthesis.cancel()
    }
  }
}
