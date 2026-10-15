import { Controller } from "@hotwired/stimulus"

// Chatten med coachen: Enter skickar, Shift+Enter ger ny rad, fältet töms
// efter skick och listan följer med nedåt när svaret strömmar in.
export default class extends Controller {
  static targets = ["messages", "input", "form"]

  connect() {
    this.scroll()
    this.observer = new MutationObserver(() => this.scroll())
    this.observer.observe(this.messagesTarget, { childList: true, subtree: true, characterData: true })
    this.inputTarget.focus()
  }

  disconnect() {
    this.observer?.disconnect()
  }

  keydown(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      if (this.inputTarget.value.trim() !== "") this.formTarget.requestSubmit()
    }
  }

  reset(event) {
    if (event.detail.success) this.formTarget.reset()
  }

  scroll() {
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }
}
