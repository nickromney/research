module ApplicationHelper
  def status_badge(status)
    badge_class = case status.to_s.downcase
                  when 'online', 'running', 'success', 'active'
                    'badge bg-success'
                  when 'offline', 'stopped', 'failed', 'inactive'
                    'badge bg-danger'
                  when 'pending', 'unknown'
                    'badge bg-warning'
                  else
                    'badge bg-secondary'
                  end

    content_tag(:span, status.to_s.titleize, class: badge_class)
  end

  def time_ago_or_never(time)
    time.present? ? "#{time_ago_in_words(time)} ago" : 'Never'
  end
end
