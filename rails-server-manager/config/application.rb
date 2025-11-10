require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile
Bundler.require(*Rails.groups)

module ServerManager
  class Application < Rails::Application
    # Initialize configuration defaults for Rails 9.0
    config.load_defaults 9.0

    # Configuration for the application, engines, and railties goes here
    config.time_zone = "UTC"
    config.active_record.default_timezone = :utc

    # Autoload lib directory
    config.autoload_paths << Rails.root.join("lib")

    # Use Solid Queue for background jobs
    config.active_job.queue_adapter = :solid_queue

    # Use Solid Cache for caching
    config.cache_store = :solid_cache_store
  end
end
