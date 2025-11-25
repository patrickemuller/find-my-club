import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="clipboard"
//
// Reusable clipboard controller for copying text to clipboard with visual feedback
//
// Usage:
//   <button data-controller="clipboard"
//           data-clipboard-text-value="text to copy"
//           data-action="click->clipboard#copy">
//     Copy
//   </button>
//
// Or with a separate button target:
//   <div data-controller="clipboard" data-clipboard-text-value="text to copy">
//     <button data-clipboard-target="button" data-action="click->clipboard#copy">
//       Copy
//     </button>
//   </div>
//
// Optional customization:
//   data-clipboard-success-message-value="Copied!"
//   data-clipboard-success-duration-value="2000"
export default class extends Controller {
  static targets = ["button"]
  static values = {
    text: String,
    successDuration: { type: Number, default: 2000 },
    successMessage: { type: String, default: "Copied!" }
  }

  connect() {
    // Check if clipboard API is available
    if (!navigator.clipboard) {
      console.warn("Clipboard API not available. Copy functionality may not work.")
    }
  }

  async copy(event) {
    event.preventDefault()

    const textToCopy = this.textValue

    if (!textToCopy) {
      console.error("No text provided to copy")
      return
    }

    try {
      await navigator.clipboard.writeText(textToCopy)
      this.showSuccess()
    } catch (err) {
      console.error("Failed to copy text:", err)
      this.showError()
    }
  }

  showSuccess() {
    const button = this.hasButtonTarget ? this.buttonTarget : this.element
    const originalHTML = button.innerHTML
    const originalClasses = button.className

    // Update button to show success state
    button.innerHTML = `
      <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
      </svg>
      <span>${this.successMessageValue}</span>
    `
    button.classList.remove("bg-gray-600", "hover:bg-gray-700")
    button.classList.add("bg-gray-500", "cursor-default")
    button.disabled = true

    // Reset button after duration
    setTimeout(() => {
      button.innerHTML = originalHTML
      button.className = originalClasses
      button.disabled = false
    }, this.successDurationValue)
  }

  showError() {
    const button = this.hasButtonTarget ? this.buttonTarget : this.element
    const originalHTML = button.innerHTML
    const originalClasses = button.className

    // Update button to show error state
    button.innerHTML = `
      <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
      </svg>
      <span>Failed</span>
    `
    button.classList.remove("bg-gray-600", "hover:bg-gray-700")
    button.classList.add("bg-red-600")
    button.disabled = true

    // Reset button after 2 seconds
    setTimeout(() => {
      button.innerHTML = originalHTML
      button.className = originalClasses
      button.disabled = false
    }, 2000)
  }
}
