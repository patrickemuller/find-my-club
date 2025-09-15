import { Controller } from "@hotwired/stimulus"

// Theme toggle controller
// - Persists theme in localStorage (key: "theme")
// - Applies [data-theme="light"|"dark"] on <html>
// - Defaults to system preference if no saved choice
export default class extends Controller {
  static targets = ["button"]

  connect() {
    // Apply current theme on connect
    this.applyTheme(this.currentTheme())
  }

  toggle() {
    const next = this.currentTheme() === "dark" ? "light" : "dark"
    this.applyTheme(next)
    try { localStorage.setItem("theme", next) } catch (_) {}
  }

  currentTheme() {
    try {
      const saved = localStorage.getItem("theme")
      if (saved === "light" || saved === "dark") return saved
    } catch (_) {}
    // Fallback to system preference
    return window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light"
  }

  applyTheme(theme) {
    const root = document.documentElement
    root.setAttribute("data-theme", theme)
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-pressed", theme === "dark" ? "true" : "false")
      this.buttonTarget.title = theme === "dark" ? "Switch to light mode" : "Switch to dark mode"
    }
  }
}
