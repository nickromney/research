require 'net/ssh'

class Server < ApplicationRecord
  # Associations
  belongs_to :project
  has_many :services, dependent: :destroy
  has_many :renewals, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :hostname, presence: true
  validates :port, numericality: { greater_than: 0, less_than: 65536 }

  # Scopes
  scope :online, -> { where(status: 'online') }
  scope :offline, -> { where(status: 'offline') }
  scope :unknown, -> { where(status: 'unknown') }

  # Methods
  def test_connection
    begin
      ssh_connect do |ssh|
        result = ssh.exec!('echo "Connection successful"')
        update(status: 'online', last_checked_at: Time.current)
        { success: true, message: 'Connection successful', output: result }
      end
    rescue => e
      update(status: 'offline', last_checked_at: Time.current)
      { success: false, message: e.message }
    end
  end

  def execute_command(command)
    ssh_connect do |ssh|
      output = ssh.exec!(command)
      { success: true, output: output }
    end
  rescue => e
    { success: false, error: e.message }
  end

  def check_all_services
    services.each(&:check_status)
  end

  def services_status_summary
    {
      running: services.where(status: 'running').count,
      stopped: services.where(status: 'stopped').count,
      unknown: services.where(status: 'unknown').count
    }
  end

  private

  def ssh_connect(&block)
    options = {
      port: port,
      timeout: 10
    }

    if ssh_key.present?
      key_data = [ssh_key]
      options[:keys] = key_data
      options[:key_data] = key_data
      options[:auth_methods] = ['publickey']
    elsif ssh_key_path.present?
      options[:keys] = [ssh_key_path]
      options[:auth_methods] = ['publickey']
    end

    Net::SSH.start(hostname, username, options, &block)
  end
end
