class Renewal < ApplicationRecord
  # Associations
  belongs_to :server

  # Validations
  validates :name, presence: true
  validates :renewal_type, presence: true
  validates :renewal_type, inclusion: {
    in: %w[ssl certificate lets_encrypt custom],
    message: "%{value} is not a valid renewal type"
  }
  validates :script, presence: true

  # Scopes
  scope :pending, -> { where(status: 'pending') }
  scope :success, -> { where(status: 'success') }
  scope :failed, -> { where(status: 'failed') }
  scope :due_for_execution, -> { where('next_execution_at <= ?', Time.current) }

  # Methods
  def execute
    update(status: 'running')

    result = server.execute_command(script)

    if result[:success]
      update(
        status: 'success',
        last_executed_at: Time.current,
        last_output: result[:output],
        next_execution_at: calculate_next_execution
      )
      { success: true, output: result[:output] }
    else
      update(
        status: 'failed',
        last_executed_at: Time.current,
        last_output: result[:error]
      )
      { success: false, error: result[:error] }
    end
  rescue => e
    update(
      status: 'failed',
      last_executed_at: Time.current,
      last_output: e.message
    )
    { success: false, error: e.message }
  end

  def test_execution
    # Test without updating status permanently
    result = server.execute_command(script)
    result
  rescue => e
    { success: false, error: e.message }
  end

  def overdue?
    next_execution_at.present? && next_execution_at < Time.current
  end

  private

  def calculate_next_execution
    return nil unless schedule.present?

    case schedule
    when 'daily'
      1.day.from_now
    when 'weekly'
      1.week.from_now
    when 'monthly'
      1.month.from_now
    when /^every_(\d+)_days$/
      $1.to_i.days.from_now
    else
      nil
    end
  end
end
