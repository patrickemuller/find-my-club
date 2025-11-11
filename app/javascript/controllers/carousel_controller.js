import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["page", "prevButton", "nextButton", "pageIndicator"]
  static values = {
    currentPage: { type: Number, default: 0 },
    itemsPerPage: { type: Number, default: 5 }
  }

  connect() {
    this.updateVisibility()
  }

  next() {
    const totalPages = this.pageTargets.length
    if (this.currentPageValue < totalPages - 1) {
      this.currentPageValue++
      this.updateVisibility()
    }
  }

  previous() {
    if (this.currentPageValue > 0) {
      this.currentPageValue--
      this.updateVisibility()
    }
  }

  updateVisibility() {
    const totalPages = this.pageTargets.length

    // Hide all pages
    this.pageTargets.forEach((page, index) => {
      if (index === this.currentPageValue) {
        page.classList.remove("hidden")
      } else {
        page.classList.add("hidden")
      }
    })

    // Update button states
    if (this.hasPrevButtonTarget) {
      if (this.currentPageValue === 0) {
        this.prevButtonTarget.disabled = true
        this.prevButtonTarget.classList.add("opacity-50", "cursor-not-allowed")
      } else {
        this.prevButtonTarget.disabled = false
        this.prevButtonTarget.classList.remove("opacity-50", "cursor-not-allowed")
      }
    }

    if (this.hasNextButtonTarget) {
      if (this.currentPageValue === totalPages - 1) {
        this.nextButtonTarget.disabled = true
        this.nextButtonTarget.classList.add("opacity-50", "cursor-not-allowed")
      } else {
        this.nextButtonTarget.disabled = false
        this.nextButtonTarget.classList.remove("opacity-50", "cursor-not-allowed")
      }
    }

    // Update page indicator
    if (this.hasPageIndicatorTarget) {
      this.pageIndicatorTarget.textContent = `${this.currentPageValue + 1} / ${totalPages}`
    }
  }
}
