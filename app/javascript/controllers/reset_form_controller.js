import { Controller } from "@hotwired/stimulus"

// Tömmer ett formulär när Turbo-svaret lyckats (snabbanteckningen).
export default class extends Controller {
  reset(event) {
    if (event.detail.success) this.element.reset()
  }
}
