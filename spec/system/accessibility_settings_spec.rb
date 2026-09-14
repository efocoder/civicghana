require "rails_helper"

RSpec.describe "Accessibility settings", type: :system do
  before { Rails.application.load_seed }

  it "opens by keyboard, applies and persists settings, and resets them" do
    visit root_path

    button = find("button", text: "Accessibility")
    button.click
    expect(button["aria-expanded"]).to eq("true")
    expect(page).to have_css("#accessibility-settings:not([hidden])")

    choose "Extra Large"
    check "High contrast"
    check "Enhanced focus"
    check "Underline links"
    check "Increase text spacing"
    check "Reduce motion"

    expect(page.evaluate_script("document.documentElement.dataset.accessibilityTextSize")).to eq("extra-large")
    expect(page.evaluate_script("document.documentElement.dataset.accessibilityHighContrast")).to eq("true")
    stored = page.evaluate_script("JSON.parse(localStorage.getItem('civicroute.accessibility.v1'))")
    expect(stored).to include("textSize" => "extra-large", "highContrast" => true, "reduceMotion" => true)

    click_button "Reset settings"
    expect(page.evaluate_script("document.documentElement.dataset.accessibilityTextSize")).to eq("normal")
    expect(page.evaluate_script("document.documentElement.dataset.accessibilityHighContrast")).to eq("false")
    expect(page).to have_content("Accessibility settings reset")
  end

  it "closes on Escape and restores focus to its control" do
    visit root_path

    click_button "Accessibility"
    find("#accessibility-settings").send_keys(:escape)

    expect(page).to have_css("#accessibility-settings[hidden]", visible: :all)
    expect(page.evaluate_script("document.activeElement.textContent.trim()")).to eq("Accessibility")
  end

  it "recovers from corrupted stored preferences" do
    visit root_path
    page.execute_script("localStorage.setItem('civicroute.accessibility.v1', '{broken')")
    refresh

    expect(page.evaluate_script("document.documentElement.dataset.accessibilityTextSize")).to eq("normal")
    expect(page.evaluate_script("document.documentElement.dataset.accessibilityHighContrast")).to eq("false")
  end

  it "disables read-aloud gracefully when browser speech is unavailable" do
    visit root_path
    page.execute_script(<<~JS)
      Object.defineProperty(window, "speechSynthesis", { value: undefined, configurable: true });
      const controller = window.Stimulus.getControllerForElementAndIdentifier(document.documentElement, "accessibility");
      controller.connect();
    JS
    click_button "Accessibility"

    expect(page).to have_button("Listen to this page", disabled: true)
    expect(page).to have_content("Read-aloud is unavailable in this browser")
  end

  it "reads long content in sentence-aware chunks instead of one breaking utterance" do
    visit root_path

    chunks = page.evaluate_script(<<~JS)
      (() => {
        const controller = window.Stimulus.getControllerForElementAndIdentifier(document.documentElement, "accessibility")
        const sentence = "This is a complete sentence designed for smooth speech. "
        return controller.splitIntoSpeechChunks(sentence.repeat(30))
      })()
    JS

    expect(chunks.length).to be > 1
    expect(chunks).to all(satisfy { |chunk| chunk.length <= 420 })
    expect(chunks.join(" ")).to include("complete sentence designed for smooth speech")
  end

  it "prefers an available female voice in the current language" do
    visit root_path

    selected_voice = page.evaluate_script(<<~JS)
      (() => {
        const controller = window.Stimulus.getControllerForElementAndIdentifier(document.documentElement, "accessibility")
        controller.availableVoices = [
          { name: "Daniel", lang: "en-GB", localService: true },
          { name: "Microsoft Aria Natural", lang: "en-GB", localService: true }
        ]
        return controller.preferredVoice("en-GB").name
      })()
    JS

    expect(selected_voice).to eq("Microsoft Aria Natural")
  end

  [ 320, 375, 390, 430, 768, 1024, 1440 ].each do |width|
    it "keeps the catalogue and settings usable at #{width}px" do
      page.current_window.resize_to(width, 900)
      visit root_path
      click_button "Accessibility"
      choose "Extra Large"
      check "High contrast"

      dimensions = page.evaluate_script(<<~JS)
        ({
          viewport: window.innerWidth,
          pageWidth: document.documentElement.scrollWidth,
          panelWidth: document.querySelector(".accessibility-dialog__panel").getBoundingClientRect().width,
          overflow: Array.from(document.querySelectorAll("body *")).filter((element) => {
            const rect = element.getBoundingClientRect()
            return rect.right > window.innerWidth + 1 || rect.left < -1
          }).slice(0, 8).map((element) => `${element.tagName}.${element.className}`)
        })
      JS
      expect(dimensions["pageWidth"]).to be <= dimensions["viewport"], dimensions["overflow"].join("\n")
      expect(dimensions["panelWidth"]).to be <= dimensions["viewport"]
      expect(page).to have_button("Reset settings")
    end
  end
end
