import { Controller } from "@hotwired/stimulus"
import { DirectUpload } from "@rails/activestorage"

export default class extends Controller {
  static targets = ["input"]

  upload(event) {
    const file = event.target.files[0]
    if (!file) return

    const url = "/rails/active_storage/direct_uploads"
    const directUpload = new DirectUpload(file, url)

    directUpload.create((error, blob) => {
      if (error) {
        console.error("Direct upload failed:", error)
        return
      }

      const imageUrl = `/rails/active_storage/blobs/redirect/${blob.signed_id}/${blob.filename}`
      this.insertMarkdownImage(file.name, imageUrl)
    })
  }

  insertMarkdownImage(name, url) {
    const textarea = document.querySelector('[data-markdown-preview-target="input"]')
    if (!textarea) return

    const imageTag = `![${name}](${url})`
    const start = textarea.selectionStart
    const before = textarea.value.substring(0, start)
    const after = textarea.value.substring(textarea.selectionEnd)

    textarea.value = `${before}${imageTag}${after}`
    textarea.dispatchEvent(new Event("input"))
  }
}
