# Kanoniska klasser för knappar, fält och ytor. Vyer ska hämta klasserna här i
# stället för att upprepa dem, så att en ändring slår igenom överallt.
# Guiden på /style_guide renderas ur exakt de här metoderna.
module StyleGuideHelper
  # Knappar. Teal är reserverat för den enda huvudhandlingen i en vy —
  # allt annat är zinc. Två tealknappar bredvid varandra är alltid fel.
  BUTTON = {
    primary: "inline-flex items-center justify-center gap-1.5 px-4 py-2 rounded-lg " \
             "bg-teal-600 hover:bg-teal-500 text-white text-sm font-medium " \
             "transition-colors disabled:opacity-50 disabled:cursor-not-allowed cursor-pointer",
    secondary: "inline-flex items-center justify-center gap-1.5 px-3 py-1.5 rounded-lg " \
               "bg-zinc-100 dark:bg-zinc-800/70 border border-zinc-200 dark:border-zinc-700/60 " \
               "text-sm text-zinc-700 dark:text-zinc-300 hover:bg-zinc-200 dark:hover:bg-zinc-700/70 " \
               "transition-colors cursor-pointer",
    solid: "inline-flex items-center justify-center gap-1.5 px-4 py-2 rounded-lg " \
           "bg-zinc-800 hover:bg-zinc-700 dark:bg-zinc-700 dark:hover:bg-zinc-600 text-white " \
           "text-sm font-medium transition-colors cursor-pointer",
    ghost: "inline-flex items-center gap-1.5 px-2 py-2 text-sm text-zinc-500 " \
           "hover:text-zinc-900 dark:hover:text-white transition-colors cursor-pointer",
    danger: "inline-flex items-center justify-center gap-1.5 px-3 py-1.5 rounded-lg " \
            "bg-red-50 hover:bg-red-100 dark:bg-red-900/20 dark:hover:bg-red-900/40 " \
            "text-red-600 dark:text-red-400 text-sm transition-colors cursor-pointer",
    chip: "inline-flex items-center px-3 py-1.5 rounded-full text-sm " \
          "bg-zinc-100 dark:bg-zinc-800/70 text-zinc-700 dark:text-zinc-300 " \
          "hover:bg-zinc-200 dark:hover:bg-zinc-700/70 transition-colors cursor-pointer",
    chip_active: "inline-flex items-center px-3 py-1.5 rounded-full text-sm font-medium " \
                 "bg-zinc-800 dark:bg-zinc-600 text-white transition-colors cursor-pointer",
    # Små val-chips, t.ex. hållning till ett ramverk.
    chip_sm: "inline-flex items-center px-2.5 py-1 rounded-full text-xs " \
             "bg-zinc-100 dark:bg-zinc-800/70 text-zinc-600 dark:text-zinc-300 " \
             "hover:bg-zinc-200 dark:hover:bg-zinc-700/70 transition-colors cursor-pointer",
    chip_sm_active: "inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium " \
                    "bg-zinc-800 dark:bg-zinc-600 text-white transition-colors cursor-pointer",
    icon: "inline-flex items-center justify-center rounded-full p-1.5 " \
          "bg-zinc-100 dark:bg-zinc-800/70 border border-zinc-200 dark:border-zinc-700/60 " \
          "text-zinc-600 dark:text-zinc-300 hover:bg-zinc-200 dark:hover:bg-zinc-700/70 " \
          "transition-colors cursor-pointer",
    # Ikonknapp som är ett valt läge, t.ex. en tumme som redan är satt.
    icon_active: "inline-flex items-center justify-center rounded-full p-1.5 " \
                 "bg-zinc-800 dark:bg-zinc-600 border border-zinc-800 dark:border-zinc-500 " \
                 "text-white hover:bg-zinc-700 dark:hover:bg-zinc-500 transition-colors cursor-pointer"
  }.freeze

  SURFACE = {
    card: "bg-white dark:bg-zinc-900/60 border border-zinc-200 dark:border-zinc-800 " \
          "rounded-2xl p-6 shadow-sm dark:shadow-none",
    panel: "rounded-xl border border-zinc-200 dark:border-zinc-700/60 bg-zinc-50 dark:bg-zinc-800/40 p-4",
    dialog: "w-full max-w-3xl rounded-2xl bg-white dark:bg-zinc-900 " \
            "border border-zinc-200 dark:border-zinc-700 p-0 backdrop:bg-zinc-900/50"
  }.freeze

  FIELD = {
    input: "w-full px-3 py-2 text-sm bg-white dark:bg-zinc-800 border border-zinc-300 dark:border-zinc-700 " \
           "rounded-lg text-zinc-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-teal-500",
    label: "block text-xs font-medium text-zinc-600 dark:text-zinc-300 mb-1.5",
    hint: "mt-1 text-xs text-zinc-500 dark:text-zinc-400",
    # Filfält: Tailwinds preflight nollställer filknappen till ren text, så
    # knappen får tillbaka sekundärknappens utseende här.
    file: "max-w-full text-sm text-zinc-600 dark:text-zinc-300 cursor-pointer " \
          "file:mr-3 file:px-3 file:py-1.5 file:rounded-lg file:border file:border-solid " \
          "file:border-zinc-200 dark:file:border-zinc-700/60 file:bg-zinc-100 dark:file:bg-zinc-800/70 " \
          "file:text-sm file:text-zinc-700 dark:file:text-zinc-300 file:cursor-pointer " \
          "hover:file:bg-zinc-200 dark:hover:file:bg-zinc-700/70 file:transition-colors"
  }.freeze

  TABLE = {
    header: "text-left py-2 px-3 text-xs font-medium text-zinc-600 dark:text-zinc-400 uppercase tracking-wide",
    row: "border-b border-zinc-100 dark:border-zinc-800/60",
    cell: "py-2 px-3 text-sm text-zinc-800 dark:text-zinc-200"
  }.freeze

  BADGE = {
    neutral: "inline-flex items-center px-2 py-0.5 rounded-full text-[11px] font-medium " \
             "bg-zinc-100 text-zinc-600 dark:bg-zinc-800 dark:text-zinc-300",
    good: "inline-flex items-center px-2 py-0.5 rounded-full text-[11px] font-medium " \
          "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-300",
    warn: "inline-flex items-center px-2 py-0.5 rounded-full text-[11px] font-medium " \
          "bg-amber-50 text-amber-700 dark:bg-amber-500/10 dark:text-amber-300",
    bad: "inline-flex items-center px-2 py-0.5 rounded-full text-[11px] font-medium " \
         "bg-red-50 text-red-700 dark:bg-red-500/10 dark:text-red-300"
  }.freeze

  # Banners som forklarar ett tillstand for hela vyn, till skillnad fran BADGE
  # som markerar en enskild rad. Amber nar vi visar nagot men det inte ar hela
  # sanningen, rott nar vi inte kan visa nagot alls.
  NOTICE = {
    info: "flex items-start gap-2 rounded-xl px-4 py-3 text-sm " \
          "border border-zinc-200 dark:border-zinc-700/60 " \
          "bg-zinc-50 dark:bg-zinc-800/40 text-zinc-700 dark:text-zinc-300",
    warn: "flex items-start gap-2 rounded-xl px-4 py-3 text-sm " \
          "border border-amber-200 dark:border-amber-500/30 " \
          "bg-amber-50 dark:bg-amber-500/10 text-amber-800 dark:text-amber-200",
    error: "flex items-start gap-2 rounded-xl px-4 py-3 text-sm " \
           "border border-red-200 dark:border-red-500/30 " \
           "bg-red-50 dark:bg-red-500/10 text-red-800 dark:text-red-200",
    # Diskret tips på en rad som leder vidare till en inställning, t.ex. att
    # lägga till röstexempel. Teal för att det är en uppmaning, inte en varning;
    # ofta en länk, därav hover-tonen.
    hint: "flex items-center gap-2.5 rounded-lg px-3 py-2 text-sm " \
          "border border-teal-200/70 dark:border-teal-500/20 " \
          "bg-teal-50/60 dark:bg-teal-500/5 text-teal-800 dark:text-teal-200 " \
          "hover:bg-teal-50 dark:hover:bg-teal-500/10 transition-colors"
  }.freeze

  def ui_button(variant = :primary) = BUTTON.fetch(variant)
  def ui_surface(variant = :card) = SURFACE.fetch(variant)
  def ui_field(variant = :input) = FIELD.fetch(variant)
  def ui_table(variant = :header) = TABLE.fetch(variant)
  def ui_badge(variant = :neutral) = BADGE.fetch(variant)
  def ui_notice(variant = :warn) = NOTICE.fetch(variant)
end
