module ApplicationHelper
  def inline_svg(filename, options = {})
    file_path = Rails.root.join("app", "assets", "icons", "#{filename}.svg")
    return unless File.exist?(file_path)

    svg = File.read(file_path)

    # Add CSS classes if provided
    if options[:class].present?
      svg = svg.sub(/<svg/, "<svg class=\"#{options[:class]}\"")
    end

    svg.html_safe
  end

  def country_options_for_select
    # Return a curated list of common countries with emoji flags
    countries = [
      { code: "us", name: "United States", dial_code: "+1" },
      { code: "ca", name: "Canada", dial_code: "+1" }
    ]

    countries.map do |country|
      flag_emoji = country[:code].upcase.chars.map { |c| (c.ord + 0x1F1A5).chr(Encoding::UTF_8) }.join
      label = "#{flag_emoji} #{country[:name]} (#{country[:dial_code]})"
      [ label, country[:code] ]
    end
  end
end
