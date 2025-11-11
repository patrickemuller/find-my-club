import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    // Close dropdown when clicking outside
    this.boundClose = this.closeOnClickOutside.bind(this)
  }

  toggle() {
    this.menuTarget.classList.toggle("hidden")

    if (!this.menuTarget.classList.contains("hidden")) {
      // Add click listener when menu opens
      document.addEventListener("click", this.boundClose)
    } else {
      // Remove click listener when menu closes
      document.removeEventListener("click", this.boundClose)
    }
  }

  close() {
    this.menuTarget.classList.add("hidden")
    document.removeEventListener("click", this.boundClose)
  }

  closeOnClickOutside(event) {
    // Close if clicking outside the dropdown
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  disconnect() {
    document.removeEventListener("click", this.boundClose)
  }
}
