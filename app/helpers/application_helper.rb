module ApplicationHelper
  # Tailwind behöver se klassnamnen i sin helhet, därför en fast tabell i
  # stället för interpolerade "bg-#{color}-500".
  AREA_COLORS = {
    "rose" => { dot: "bg-rose-500", text: "text-rose-600 dark:text-rose-400", soft: "bg-rose-50 text-rose-700 dark:bg-rose-500/10 dark:text-rose-300", hex: "#f43f5e" },
    "lime" => { dot: "bg-lime-500", text: "text-lime-600 dark:text-lime-400", soft: "bg-lime-50 text-lime-700 dark:bg-lime-500/10 dark:text-lime-300", hex: "#84cc16" },
    "violet" => { dot: "bg-violet-500", text: "text-violet-600 dark:text-violet-400", soft: "bg-violet-50 text-violet-700 dark:bg-violet-500/10 dark:text-violet-300", hex: "#8b5cf6" },
    "amber" => { dot: "bg-amber-500", text: "text-amber-600 dark:text-amber-400", soft: "bg-amber-50 text-amber-700 dark:bg-amber-500/10 dark:text-amber-300", hex: "#f59e0b" },
    "sky" => { dot: "bg-sky-500", text: "text-sky-600 dark:text-sky-400", soft: "bg-sky-50 text-sky-700 dark:bg-sky-500/10 dark:text-sky-300", hex: "#0ea5e9" },
    "teal" => { dot: "bg-teal-500", text: "text-teal-600 dark:text-teal-400", soft: "bg-teal-50 text-teal-700 dark:bg-teal-500/10 dark:text-teal-300", hex: "#14b8a6" },
    "emerald" => { dot: "bg-emerald-500", text: "text-emerald-600 dark:text-emerald-400", soft: "bg-emerald-50 text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-300", hex: "#10b981" },
    "indigo" => { dot: "bg-indigo-500", text: "text-indigo-600 dark:text-indigo-400", soft: "bg-indigo-50 text-indigo-700 dark:bg-indigo-500/10 dark:text-indigo-300", hex: "#6366f1" }
  }.freeze

  def area_color(area, variant = :dot)
    AREA_COLORS.fetch(area.color, AREA_COLORS["teal"])[variant]
  end

  # Lucide-ikon, ritas av icons-controllern.
  def icon(name, css: "w-4 h-4")
    tag.i(data: { lucide: name }, class: "inline-block shrink-0 #{css}", "aria-hidden": true)
  end

  def area_badge(key)
    area = key.is_a?(Area) ? key : Area.find(key)
    return unless area
    tag.span(class: "inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-medium #{area_color(area, :soft)}") do
      safe_join([ icon(area.icon, css: "w-3 h-3"), area.name ])
    end
  end

  def markdown(text)
    renderer = Redcarpet::Render::HTML.new(filter_html: true, hard_wrap: true, link_attributes: { rel: "noopener", target: "_blank" })
    html = Redcarpet::Markdown.new(renderer, autolink: true, no_intra_emphasis: true, lax_spacing: true).render(text.to_s)
    sanitize(html)
  end

  def page_header(title, subtitle = nil, &actions)
    tag.div(class: "flex flex-wrap items-start justify-between gap-4 mb-6") do
      safe_join([
        tag.div { safe_join([ tag.h1(title, class: "text-2xl font-semibold text-zinc-900 dark:text-white"),
                              (tag.p(subtitle, class: "mt-1 text-sm text-zinc-500 dark:text-zinc-400") if subtitle) ].compact) },
        (tag.div(class: "flex items-center gap-2", &actions) if actions)
      ].compact)
    end
  end

  def empty_state(text)
    tag.p(text, class: "text-sm text-zinc-500 dark:text-zinc-400 italic")
  end

  def number_display(value)
    number_with_precision(value, precision: 2, strip_insignificant_zeros: true, delimiter: " ")
  end

  # En liten trendlinje för en serie mätvärden.
  def sparkline(values, width: 120, height: 32, color: "#14b8a6")
    values = values.map(&:to_f)
    return tag.span("–", class: "text-zinc-400") if values.size < 2

    min, max = values.minmax
    span = (max - min).zero? ? 1 : max - min
    step = width.to_f / (values.size - 1)
    points = values.each_with_index.map { |v, i| "#{(i * step).round(1)},#{(height - 2 - ((v - min) / span) * (height - 4)).round(1)}" }
    tag.svg(width: width, height: height, viewBox: "0 0 #{width} #{height}", class: "overflow-visible") do
      tag.polyline(points: points.join(" "), fill: "none", stroke: color, "stroke-width": 2, "stroke-linecap": "round", "stroke-linejoin": "round")
    end
  end

  # Ett större linjediagram med referensintervall, för mätvärdessidan.
  def line_chart(measurements, width: 640, height: 220)
    data = measurements.sort_by(&:measured_at)
    return empty_state(t("measurements.too_few")) if data.size < 2

    pad = 28
    values = data.map { _1.value.to_f }
    low = data.filter_map(&:reference_low).map(&:to_f).min
    high = data.filter_map(&:reference_high).map(&:to_f).max
    min, max = (values + [ low, high ].compact).minmax
    min -= (max - min) * 0.1
    max += (max - min) * 0.1
    max = min + 1 if max == min
    t0, t1 = data.first.measured_at.to_f, data.last.measured_at.to_f
    t1 = t0 + 1 if t1 == t0
    x = ->(t) { pad + (t - t0) / (t1 - t0) * (width - 2 * pad) }
    y = ->(v) { height - pad - (v - min) / (max - min) * (height - 2 * pad) }

    tag.svg(viewBox: "0 0 #{width} #{height}", class: "w-full h-auto text-zinc-400") do
      parts = []
      parts << tag.rect(x: pad, y: y.(high), width: width - 2 * pad, height: (y.(low) - y.(high)).abs, fill: "#14b8a6", opacity: 0.08) if low && high
      parts << tag.polyline(points: data.map { "#{x.(_1.measured_at.to_f).round(1)},#{y.(_1.value.to_f).round(1)}" }.join(" "),
                            fill: "none", stroke: "#14b8a6", "stroke-width": 2.5, "stroke-linejoin": "round")
      data.each do |m|
        parts << tag.circle(cx: x.(m.measured_at.to_f).round(1), cy: y.(m.value.to_f).round(1), r: 3.5,
                            fill: m.out_of_range? ? "#ef4444" : "#14b8a6") { tag.title("#{l(m.measured_at.to_date)}: #{number_display(m.value)} #{m.unit}") }
      end
      [ min, max ].each { |v| parts << tag.text(number_display(v.round(1)), x: 2, y: y.(v) + 4, "font-size": 10, fill: "currentColor") }
      parts << tag.text(l(data.first.measured_at.to_date, format: :short), x: pad, y: height - 6, "font-size": 10, fill: "currentColor")
      parts << tag.text(l(data.last.measured_at.to_date, format: :short), x: width - pad, y: height - 6, "font-size": 10, fill: "currentColor", "text-anchor": "end")
      safe_join(parts)
    end
  end

  # Livshjulet: skattningen per område som ett radardiagram.
  def life_wheel(life_areas, size: 280)
    areas = life_areas.to_a
    return if areas.size < 3

    c = size / 2.0
    r = c - 34
    angle = ->(i) { -Math::PI / 2 + i * 2 * Math::PI / areas.size }
    pt = ->(i, v) { [ c + Math.cos(angle.(i)) * r * v / 10.0, c + Math.sin(angle.(i)) * r * v / 10.0 ] }

    # Extra marginal i sidled så att långa etiketter ("Mening & värderingar") får plats.
    pad = 80
    tag.svg(viewBox: "#{-pad} 0 #{size + 2 * pad} #{size}", class: "w-full max-w-md mx-auto text-zinc-300 dark:text-zinc-700") do
      parts = []
      [ 2.5, 5, 7.5, 10 ].each do |lvl|
        parts << tag.polygon(points: areas.each_index.map { pt.(_1, lvl).map { |n| n.round(1) }.join(",") }.join(" "),
                             fill: "none", stroke: "currentColor", "stroke-width": 1)
      end
      areas.each_with_index do |la, i|
        ex, ey = pt.(i, 10)
        parts << tag.line(x1: c, y1: c, x2: ex.round(1), y2: ey.round(1), stroke: "currentColor", "stroke-width": 1)
        lx, ly = pt.(i, 11.6)
        anchor = (lx - c).abs < 1 ? "middle" : (lx > c ? "start" : "end")
        parts << link_to(area_path(la)) do
          tag.text(la.area.name, x: lx.round(1), y: ly.round(1) + 4, "text-anchor": anchor, "font-size": 11,
                   class: "fill-zinc-600 dark:fill-zinc-300 hover:fill-teal-600")
        end
      end
      poly = areas.each_with_index.map { |la, i| pt.(i, la.rating || 0).map { _1.round(1) }.join(",") }
      parts << tag.polygon(points: poly.join(" "), fill: "#14b8a6", "fill-opacity": 0.18, stroke: "#14b8a6", "stroke-width": 2)
      areas.each_with_index do |la, i|
        next unless la.rating
        px, py = pt.(i, la.rating)
        parts << tag.circle(cx: px.round(1), cy: py.round(1), r: 4, fill: AREA_COLORS.dig(la.color, :hex)) { tag.title("#{la.name}: #{la.rating}/10") }
      end
      safe_join(parts)
    end
  end
end
