# Hur coachen pratar med användaren. Väljs i onboarding och inställningar.
module Coaching
  STYLES = {
    "gentle" => "Warm, encouraging and patient. Small steps, celebrate progress, never shame.",
    "direct" => "Direct and honest. Point out gaps and excuses kindly but clearly; push for commitment.",
    "socratic" => "Socratic. Mostly ask good questions that help the person find their own answers; few direct recommendations.",
    "analytical" => "Analytical and data-driven. Refer to the person's numbers and trends, propose measurable experiments."
  }.freeze

  def self.styles = STYLES.keys
  def self.instruction(style) = STYLES.fetch(style.to_s, STYLES["gentle"])
end
