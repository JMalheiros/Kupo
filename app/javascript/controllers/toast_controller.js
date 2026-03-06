import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { duration: { type: Number, default: 5000 } }

  connect() {
    this.element.classList.add("animate-in", "fade-in", "slide-in-from-right")
    this.timeout = setTimeout(() => this.dismiss(), this.durationValue)
  }

  disconnect() {
    if (this.timeout) clearTimeout(this.timeout)
  }

  dismiss() {
    this.element.classList.add("animate-out", "fade-out", "slide-out-to-right")
    this.element.addEventListener("animationend", () => this.element.remove(), { once: true })
    // Fallback removal if animation doesn't fire
    setTimeout(() => this.element.remove(), 300)
  }
}
