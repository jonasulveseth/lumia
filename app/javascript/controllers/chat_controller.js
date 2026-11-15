import { Controller } from "@hotwired/stimulus"

// Chatten med coachen: Enter skickar, Shift+Enter ger ny rad, fältet töms
// efter skick och listan följer med nedåt när svaret strömmar in.
//
// Svaret strömmar in som Turbo Stream-replace över websocket. Två saker kan gå
// snett där, och båda hanteras här:
// - Uppdateringar kan komma fram i fel ordning. Varje meddelande bär därför
//   data-final/data-length, och en äldre version får aldrig skriva över en nyare.
// - Uppdateringar kan utebli (anslutningen sov, mobilen låstes). Väntar ett svar
//   och inget har hänt på en stund hämtas sidan om (morph), likaså när fliken
//   blir synlig igen.
export default class extends Controller {
  static targets = ["messages", "input", "form"]
  static values = { patience: { type: Number, default: 8000 } }

  connect() {
    this.scroll()
    this.observer = new MutationObserver(() => {
      this.scroll()
      this.watch()
    })
    this.observer.observe(this.messagesTarget, { childList: true, subtree: true, characterData: true })
    this.guard = this.guard.bind(this)
    this.wake = this.wake.bind(this)
    document.addEventListener("turbo:before-stream-render", this.guard)
    document.addEventListener("visibilitychange", this.wake)
    this.watch()
    this.inputTarget.focus()
  }

  disconnect() {
    this.observer?.disconnect()
    clearTimeout(this.timer)
    document.removeEventListener("turbo:before-stream-render", this.guard)
    document.removeEventListener("visibilitychange", this.wake)
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

  // Stoppar en replace som skulle ersätta ett meddelande med en äldre version av sig självt.
  guard(event) {
    const stream = event.target
    if (stream.action !== "replace") return
    const current = document.getElementById(stream.target)
    if (!current || !this.messagesTarget.contains(current) || !("final" in current.dataset)) return
    const incoming = stream.templateContent?.firstElementChild
    if (incoming && this.age(incoming) < this.age(current)) event.preventDefault()
  }

  age(message) {
    return message.dataset.final === "true" ? Infinity : Number(message.dataset.length || 0)
  }

  // Så länge ett svar väntas: hämta om sidan om inget händer.
  watch() {
    clearTimeout(this.timer)
    if (this.waiting) this.timer = setTimeout(() => this.refresh(), this.patienceValue)
  }

  wake() {
    if (!document.hidden && this.waiting) this.refresh()
  }

  refresh() {
    window.Turbo.visit(window.location.href, { action: "replace" })
    this.watch()
  }

  get waiting() {
    return this.messagesTarget.querySelector('[data-final="false"]') !== null
  }
}
