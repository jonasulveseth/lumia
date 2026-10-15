import { Controller } from "@hotwired/stimulus"
import { createIcons, icons } from "lucide"

// Ritar Lucide-ikoner (<i data-lucide="…">). Sitter på <body> och ritar om
// när Turbo byter ut delar av sidan, så att strömmade element också får ikoner.
export default class extends Controller {
  connect() {
    this.render()
    this.observer = new MutationObserver(() => this.render())
    this.observer.observe(this.element, { childList: true, subtree: true })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  render() {
    if (!this.element.querySelector("i[data-lucide]")) return
    createIcons({ icons, attrs: { "stroke-width": 1.75 } })
  }
}
