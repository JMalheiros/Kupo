import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.handleKeydown = (event) => {
      if (event.key === "Escape") this.close()
    }
    document.addEventListener("keydown", this.handleKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown)
  }

  close() {
    this.element.remove()

    // Restore URL if modal was opened via Turbo
    if (window.history.length > 1) {
      window.history.back()
    }
  }
}
