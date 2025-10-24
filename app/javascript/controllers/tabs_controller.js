import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]
  static classes = ["active", "inactive"]
  static values = {
    defaultTab: { type: String, default: "active" }
  }

  connect() {
    this.showTab(this.defaultTabValue)
  }

  select(event) {
    event.preventDefault()
    const tabName = event.currentTarget.dataset.tabName
    this.showTab(tabName)
  }

  showTab(tabName) {
    // Update tab buttons
    this.tabTargets.forEach(tab => {
      const isActive = tab.dataset.tabName === tabName

      if (isActive) {
        tab.classList.remove('border-transparent', 'text-gray-500', 'dark:text-gray-400')
        tab.classList.add('border-orange-500', 'text-orange-600', 'dark:text-orange-400')
      } else {
        tab.classList.remove('border-orange-500', 'text-orange-600', 'dark:text-orange-400')
        tab.classList.add('border-transparent', 'text-gray-500', 'dark:text-gray-400')
      }
    })

    // Update panels
    this.panelTargets.forEach(panel => {
      if (panel.dataset.tabName === tabName) {
        panel.classList.remove('hidden')
      } else {
        panel.classList.add('hidden')
      }
    })
  }
}
