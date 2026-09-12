import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "response", "answer", "sources", "loading", "error"]
  static values = { url: String, type: String }

  connect() {
    this.loading = false
  }

  async ask(event) {
    event.preventDefault()
    if (this.loading) return

    const form = event.target.closest("form")
    const input = form?.querySelector("input[name='question'], textarea[name='question']")
    const question = input ? input.value.trim() : (event.target.dataset.aiQuestionParam || "")

    if (!question) {
      this.showError("Please enter a question.")
      return
    }

    const serviceInput = form?.querySelector("input[name='service_slug']")
    const serviceSlug = serviceInput?.value || event.target.dataset.aiServiceParam
    await this.execute(this.urlValue, {
      question: question,
      ...(serviceSlug ? { service_slug: serviceSlug } : {})
    })
  }

  async explainCase(event) {
    event.preventDefault()
    if (this.loading) return
    await this.execute(this.urlValue, {})
  }

  async explainAction(event) {
    event.preventDefault()
    if (this.loading) return
    await this.execute(this.urlValue, {})
  }

  async refineDraft(event) {
    event.preventDefault()
    if (this.loading) return

    const draftBody = document.getElementById("draft-body")
    const tone = event.target.dataset.tone || "clearer"

    if (!draftBody || !draftBody.value.trim()) {
      this.showError("No draft text to refine.")
      return
    }

    await this.execute(this.urlValue, {
      draft_text: draftBody.value,
      tone: tone
    })
  }

  async execute(url, body) {
    this.lastRequest = { url, body }
    this.setLoading(true)
    this.hideError()
    this.hideResponse()

    try {
      const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
      const response = await fetch(url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": csrfToken
        },
        body: JSON.stringify(body)
      })

      if (response.status === 429) {
        this.showError("Too many requests. Please wait a moment and try again.")
        return
      }

      if (!response.ok) {
        this.showError("Something went wrong. Please try again.")
        return
      }

      const data = await response.json()

      if (data.error) {
        this.showError(data.error)
        return
      }

      if (data.refined_text !== undefined) {
        this.showRefinedDraft(data.refined_text, data.valid)
      } else {
        this.showAnswer(data.answer, data.sources || [], data.valid)
      }
    } catch (err) {
      this.showError("AI explanation is temporarily unavailable. Your verified case assessment and recommended action remain available below.")
    } finally {
      this.setLoading(false)
    }
  }

  async retry(event) {
    event.preventDefault()
    if (this.lastRequest) await this.execute(this.lastRequest.url, this.lastRequest.body)
  }

  showAnswer(answer, sources, valid) {
    if (this.hasAnswerTarget) {
      this.answerTarget.innerHTML = this.formatAiText(answer)
    }

    if (this.hasSourcesTarget && sources.length > 0) {
      this.sourcesTarget.innerHTML = sources.map(s =>
        `<div class="text-xs text-base-content/60 mt-1">
          <span class="font-semibold">${this.escapeHtml(s.title)}</span>
          ${s.section ? ` — ${this.escapeHtml(s.section)}` : ""}
          ${s.url ? ` <a href="${this.escapeHtml(s.url)}" target="_blank" rel="noopener noreferrer" class="link">View source</a>` : ""}
        </div>`
      ).join("")
    } else if (this.hasSourcesTarget) {
      this.sourcesTarget.innerHTML = ""
    }

    if (this.hasResponseTarget) {
      this.responseTarget.classList.remove("hidden")
    }
  }

  showRefinedDraft(refinedText, valid) {
    const draftBody = document.getElementById("draft-body")
    if (draftBody) {
      draftBody.value = refinedText.replace(/\*\*/g, "")
    }

    if (this.hasResponseTarget) {
      this.responseTarget.classList.add("hidden")
    }
  }

  showError(message) {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = message
      this.errorTarget.classList.remove("hidden")
    }
  }

  hideResponse() {
    if (this.hasResponseTarget) {
      this.responseTarget.classList.add("hidden")
    }
  }

  hideError() {
    if (this.hasErrorTarget) {
      this.errorTarget.classList.add("hidden")
    }
  }

  setLoading(state) {
    this.loading = state
    if (this.hasButtonTarget) {
      this.buttonTarget.disabled = state
    }
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.toggle("hidden", !state)
    }
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }

  formatAiText(text) {
    // Citations are rendered from CivicRoute's verified source cards below;
    // remove provider-generated inline source labels from the prose so they
    // are not duplicated or presented as provider-authored links.
    // Providers sometimes append citations such as "*(Source: ...))*".
    // CivicRoute renders authoritative citations as source cards, so remove
    // the entire provider-generated source line (including nested brackets).
    const withoutInlineSources = (text || "").replace(/(?:\*+\s*)?\(?\s*Source:\s*[^\n]*(?:\n|$)/gi, "")
    const escaped = this.escapeHtml(withoutInlineSources)
    return escaped
      .replace(/\*\*(.+?)\*\*/g, "<strong>$1</strong>")
      .replace(/\n/g, "<br>")
  }
}
