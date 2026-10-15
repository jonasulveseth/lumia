import { Controller } from "@hotwired/stimulus"

// Visar värdet bredvid ett skjutreglage (1–10).
export default class extends Controller {
  static targets = ["input", "output"]

  connect() { this.update() }

  update() {
    this.outputTarget.textContent = this.inputTarget.value
  }
}
