class Service < ApplicationRecord
  # Associations
  belongs_to :server

  # Validations
  validates :name, presence: true
  validates :service_type, presence: true
  validates :service_type, inclusion: {
    in: %w[systemd docker process custom],
    message: "%{value} is not a valid service type"
  }

  # Callbacks
  before_create :set_default_check_command

  # Scopes
  scope :running, -> { where(status: 'running') }
  scope :stopped, -> { where(status: 'stopped') }
  scope :unknown, -> { where(status: 'unknown') }

  # Methods
  def check_status
    command = check_command || default_check_command

    result = server.execute_command(command)

    if result[:success]
      output = result[:output].to_s.strip
      new_status = determine_status_from_output(output)

      update(
        status: new_status,
        status_output: output,
        last_checked_at: Time.current
      )

      { success: true, status: new_status, output: output }
    else
      update(
        status: 'unknown',
        status_output: result[:error],
        last_checked_at: Time.current
      )

      { success: false, error: result[:error] }
    end
  rescue => e
    update(status: 'unknown', status_output: e.message, last_checked_at: Time.current)
    { success: false, error: e.message }
  end

  private

  def set_default_check_command
    self.check_command ||= default_check_command
  end

  def default_check_command
    case service_type
    when 'systemd'
      "systemctl is-active #{name}"
    when 'docker'
      "docker ps --filter name=#{name} --filter status=running --format '{{.Names}}'"
    when 'process'
      "pgrep -f #{name} > /dev/null && echo 'running' || echo 'stopped'"
    else
      check_command
    end
  end

  def determine_status_from_output(output)
    case service_type
    when 'systemd'
      output.include?('active') ? 'running' : 'stopped'
    when 'docker'
      output.present? && output.include?(name) ? 'running' : 'stopped'
    when 'process'
      output.include?('running') ? 'running' : 'stopped'
    else
      # For custom commands, look for common indicators
      if output =~ /running|active|up|ok/i
        'running'
      elsif output =~ /stopped|inactive|down|failed/i
        'stopped'
      else
        'unknown'
      end
    end
  end
end
