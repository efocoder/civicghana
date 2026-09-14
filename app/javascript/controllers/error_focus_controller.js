import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["summary"]

  connect() {
    if (!this.hasSummaryTarget) return
    requestAnimationFrame(() => this.summaryTarget.focus({ preventScroll: true }))
    this.summaryTarget.scrollIntoView({ block: "start", behavior: "auto" })
  }
}
