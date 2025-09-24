import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="tooltip"
// Minimal click-to-toggle tooltip, no external CSS required (uses Tailwind classes if available)
export default class extends Controller {
  static targets = ["button", "panel"]

  connect() {
    console.log("Tooltip connected")
    this._onDocumentClick = this.handleDocumentClick.bind(this)
    this._onKeydown = this.handleKeydown.bind(this)
    document.addEventListener("click", this._onDocumentClick)
    document.addEventListener("keydown", this._onKeydown)
  }

  disconnect() {
    document.removeEventListener("click", this._onDocumentClick)
    document.removeEventListener("keydown", this._onKeydown)
  }

  toggle() {
    if (this.isOpen()) {
      this.hide()
    } else {
      this.show()
    }
  }

  show() {
    if (!this.hasPanelTarget) return
    this.panelTarget.classList.remove("hidden")
    if (this.hasButtonTarget) this.buttonTarget.setAttribute("aria-expanded", "true")
  }

  hide() {
    if (!this.hasPanelTarget) return
    this.panelTarget.classList.add("hidden")
    if (this.hasButtonTarget) this.buttonTarget.setAttribute("aria-expanded", "false")
  }

  isOpen() {
    return this.hasPanelTarget && !this.panelTarget.classList.contains("hidden")
  }

  handleDocumentClick(event) {
    if (!this.element.contains(event.target)) {
      this.hide()
    }
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.hide()
    }
  }
}
