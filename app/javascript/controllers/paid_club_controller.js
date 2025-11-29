import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "stripeInfo"]

  connect() {
    this.toggle()
  }

  toggle() {
    if (this.checkboxTarget.checked) {
      this.stripeInfoTarget.classList.remove("hidden")
    } else {
      this.stripeInfoTarget.classList.add("hidden")
    }
  }
}
