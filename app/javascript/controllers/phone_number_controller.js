import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="phone-number"
export default class extends Controller {
  static targets = ["countrySelect", "flagDisplay"]

  connect() {
    this.updateFlag()
  }

  updateFlag() {
    const countryCode = this.countrySelectTarget.value
    if (!countryCode) return

    // Update flag display if target exists
    if (this.hasFlagDisplayTarget) {
      const flagPath = `/assets/icons/country_flags/${countryCode}.svg`
      this.flagDisplayTarget.innerHTML = `<img src="${flagPath}" alt="${countryCode}" class="w-6 h-4 inline-block" onerror="this.style.display='none'" />`
    }
  }
}
