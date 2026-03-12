import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { duration: { type: Number, default: 5000 } }

  connect() {
    this.element.classList.add("animate-in", "fade-in-0", "slide-in-from-right-full")
    this.timeout = setTimeout(() => this.dismiss(), this.durationValue)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  dismiss() {
    this.element.classList.remove("animate-in", "fade-in-0", "slide-in-from-right-full")
    this.element.classList.add("animate-out", "fade-out-0", "slide-out-to-right-full")
    this.element.addEventListener("animationend", () => this.element.remove(), { once: true })
    setTimeout(() => this.element.remove(), 300)
  }
}
