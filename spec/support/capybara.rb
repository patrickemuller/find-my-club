require "capybara/rspec"

module TurboHelpers
  # Wait for a Turbo Frame to finish loa
  def wait_for_turbo_frame(frame_id, timeout: 5)
    has_css?("turbo-frame##{frame_id}[complete]", wait: timeout) ||
      has_css?("turbo-frame##{frame_id}[src]:not([busy])", wait: timeout) ||
      has_css?("turbo-frame##{frame_id}", wait: timeout)
  end
  # Wait for Turbo to finish all requests
  def wait_for_turbo(timeout: 5)
    Timeout.timeout(timeout) do
      loop do
        break if page.evaluate_script('typeof Turbo === "undefined" || !Turbo.navigator.formSubmission?.isBusy()')
        sleep 0.1
      end
    end
  rescue Timeout::Error
    # Continue if Turbo isn't available or timeout
  end

  # Wait for content to appear after Turbo update
  def wait_for_turbo_content(content, timeout: 5)
    has_content?(content, wait: timeout)
  end

  # Wait for content to disappear after Turbo update
  def wait_for_turbo_removal(content)
    !wait_for_turbo_content(content)
  end
end

RSpec.configure do |config|
  config.include TurboHelpers, type: :system
end
