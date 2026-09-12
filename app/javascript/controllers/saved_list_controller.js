import { Controller } from "@hotwired/stimulus"
import { SavedItemsStore } from "lib/saved_items_store"

export default class extends Controller {
  static targets = ["content", "empty"]
  static values = { continueLabel: String, viewLabel: String, removeLabel: String, confirmLabel: String }
  connect() { this.render(); this.listener = () => this.render(); window.addEventListener("civicroute:saved-changed", this.listener) }
  disconnect() { window.removeEventListener("civicroute:saved-changed", this.listener) }
  render() {
    const items = SavedItemsStore.list()
    this.emptyTarget.hidden = items.length > 0
    this.contentTarget.innerHTML = items.length ? items.map((item) => `<article class="card border border-base-300 bg-base-100"><div class="card-body"><h2 class="card-title">${this.escape(item.title)}</h2><p class="text-sm text-base-content/70">${this.escape(item.agency_name || "")}</p><div class="card-actions justify-end"><a class="btn btn-primary btn-sm" href="${this.escape(item.url || "#")}">${item.type === "case" ? this.continueLabelValue : this.viewLabelValue}</a><button class="btn btn-ghost btn-sm" data-action="saved-list#remove" data-type="${item.type}" data-public-id="${item.public_id}">${this.removeLabelValue}</button></div></div></article>`).join("") : ""
  }
  remove(event) { SavedItemsStore.remove(event.params.type, event.params.publicId); this.render() }
  clear() { if (window.confirm(this.confirmLabelValue)) { SavedItemsStore.clear(); this.render() } }
  escape(value) { const div = document.createElement("div"); div.textContent = value; return div.innerHTML }
}
