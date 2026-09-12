import { Controller } from "@hotwired/stimulus"
import { SavedItemsStore } from "lib/saved_items_store"

export default class extends Controller {
  static values = { type: String, publicId: String, item: Object, savedLabel: String, saveLabel: String, removeLabel: String, unavailableLabel: String }
  static targets = ["button", "state", "message"]

  connect() { this.refresh() }

  refresh() {
    if (!this.hasTypeValue || !this.hasPublicIdValue) return
    const saved = SavedItemsStore.exists(this.typeValue, this.publicIdValue)
    if (this.hasButtonTarget) this.buttonTarget.textContent = saved ? this.removeLabelValue : this.saveLabelValue
    if (this.hasStateTarget) this.stateTarget.textContent = saved ? this.savedLabelValue : ""
    this.element.dataset.saved = saved
  }

  toggle() {
    const saved = SavedItemsStore.exists(this.typeValue, this.publicIdValue)
    let item = this.itemValue
    if (!item || typeof item !== "object") {
      try { item = JSON.parse(this.element.dataset.savedItemItemValue) } catch (_) { item = { type: this.typeValue, public_id: this.publicIdValue } }
    }
    const ok = saved ? SavedItemsStore.remove(this.typeValue, this.publicIdValue) : SavedItemsStore.save(item)
    if (!ok && this.hasMessageTarget) this.messageTarget.textContent = this.unavailableLabelValue
    this.refresh()
    window.dispatchEvent(new CustomEvent("civicroute:saved-changed"))
  }

  remove() { SavedItemsStore.remove(this.typeValue, this.publicIdValue); this.element.remove(); window.dispatchEvent(new CustomEvent("civicroute:saved-changed")) }

  copyLink() {
    const url = window.location.href
    const success = () => { if (this.hasMessageTarget) this.messageTarget.textContent = this.element.dataset.copiedLabel || "Private link copied" }
    const failure = () => { if (this.hasMessageTarget) this.messageTarget.textContent = this.element.dataset.copyFallback || "Copy the browser address manually." }
    if (navigator.clipboard && window.isSecureContext) {
      navigator.clipboard.writeText(url).then(success).catch(() => this.manualCopy(url, success, failure))
    } else {
      this.manualCopy(url, success, failure)
    }
  }

  manualCopy(url, success, failure) {
    try {
      const input = document.createElement("textarea")
      input.value = url; input.style.position = "fixed"; input.style.opacity = "0"
      document.body.appendChild(input); input.focus(); input.select()
      const copied = document.execCommand("copy")
      input.remove(); copied ? success() : failure()
    } catch (_) { failure() }
  }
}
