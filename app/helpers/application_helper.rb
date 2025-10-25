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
end
