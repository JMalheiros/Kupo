import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  async upload(event) {
    const file = event.target.files[0]
    if (!file) return

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    const response = await fetch("/rails/active_storage/direct_uploads", {
      method: "POST",
      headers: {
        "X-CSRF-Token": csrfToken,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        blob: {
          filename: file.name,
          content_type: file.type,
          byte_size: file.size,
          checksum: await this.computeChecksum(file),
        },
      }),
    })

    if (response.ok) {
      const blob = await response.json()
      const url = `/rails/active_storage/blobs/redirect/${blob.signed_id}/${blob.filename}`
      this.insertMarkdownImage(file.name, url)
      await this.uploadToSignedUrl(blob.direct_upload.url, blob.direct_upload.headers, file)
    }
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

  async uploadToSignedUrl(url, headers, file) {
    await fetch(url, {
      method: "PUT",
      headers: headers,
      body: file,
    })
  }

  async computeChecksum(file) {
    const buffer = await file.arrayBuffer()
    const hashBuffer = await crypto.subtle.digest("SHA-256", buffer)
    return btoa(String.fromCharCode(...new Uint8Array(hashBuffer)))
  }
}
