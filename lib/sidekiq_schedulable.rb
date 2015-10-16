require 'sidekiq'
require 'sidekiq/schedulable'
require 'sidekiq_schedulable/startup'
require 'sidekiq_schedulable/middleware/server'
require 'sidekiq_schedulable/middleware/client'

module SidekiqSchedulable
  def self.schedules
    @schedules ||= {}
  end

  def self.boot!
    Sidekiq.configure_server do |config|
      config.server_middleware do |chain|
        chain.add Middleware::Server, schedules
      end

      config.client_middleware do |chain|
        chain.add Middleware::Client, schedules
      end

      config.on(:startup) do
        Startup.new(schedules, Sidekiq::ScheduledSet.new).schedule!
      end
    end

    Sidekiq.configure_client do |config|
      config.client_middleware do |chain|
        chain.add Middleware::Client, schedules
      end
    end
  end
end

SidekiqSchedulable.boot!
