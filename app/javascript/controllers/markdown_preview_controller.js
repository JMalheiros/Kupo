import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview"]

  async fetchPreview() {
    const body = this.inputTarget.value
    if (!body.trim()) {
      this.previewTarget.innerHTML = ""
      return
    }

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    const response = await fetch("/articles/markdown_preview", {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "X-CSRF-Token": csrfToken,
      },
      body: `body=${encodeURIComponent(body)}`,
    })

    if (response.ok) {
      const html = await response.text()
      this.previewTarget.innerHTML = html
    }
  }
}
