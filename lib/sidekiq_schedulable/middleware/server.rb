require 'sidekiq_schedulable/schedule'

module SidekiqSchedulable
  module Middleware
    class Server
      def initialize(schedules = {})
        @schedules = schedules
      end

      def call(worker, item, queue)
        yield
      ensure
        schedule_next_job(item) if item['scheduled']
      end

      private

      def schedule_next_job(item)
        class_name = item['class']
        if schedule = @schedules[class_name]
          time = Schedule.next_time(schedule[:at])
          schedule[:worker].perform_at(time)
        end
      end
    end
  end
end
