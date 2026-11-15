import { Controller } from "@hotwired/stimulus"

// Minns om en <details> är öppen eller stängd (per flik), så att valet står sig
// när elementet byts ut av en Turbo Stream eller sidan hämtas om. Elementet behöver ett id.
export default class extends Controller {
  connect() {
    this.restore()
  }

  // Även efter en morph-uppdatering, som annars återställer till sidans standardläge.
  restore() {
    const saved = this.read()
    if (saved !== null) this.element.open = saved === "open"
  }

  remember() {
    try {
      sessionStorage.setItem(this.key, this.element.open ? "open" : "closed")
    } catch {
      // Privat läge eller blockerad lagring: då gäller standardläget.
    }
  }

  read() {
    try {
      return sessionStorage.getItem(this.key)
    } catch {
      return null
    }
  }

  get key() {
    return `disclosure:${this.element.id}`
  }
}
