import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.toggleFields()
    this.toggleMilestoneField()
  }

  toggleFields() {
    const portal = this.element.querySelector('input[name="case_observation[observation_type]"][value="portal"]')
    const isPortal = portal?.checked === true
    this.setDisplay("non-portal-fields", !isPortal)
    this.setDisplay("summary-field", !isPortal)
    this.setDisplay("portal-snapshot-fields", isPortal)
  }

  toggleMilestoneField() {
    const milestone = this.element.querySelector('input[name="case_observation[progress_claim]"][value="public_milestone"]')
    this.setDisplay("milestone-select", milestone?.checked === true)
  }

  setDisplay(id, visible) {
    const element = this.element.querySelector(`#${id}`)
    if (element) element.style.display = visible ? "block" : "none"
  }
}
