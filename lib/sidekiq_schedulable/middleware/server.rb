require 'sidekiq_schedulable/schedule'

module SidekiqSchedulable
  module Middleware
    class Server
      def initialize(schedules = {})
        @schedules = schedules
      end

      def call(worker, item, queue)
        start_time = Time.now
        yield
      ensure
        schedule_next_job(item, start_time) if item['scheduled']
      end

      private

      def schedule_next_job(item, start_time)
        class_name = item['class']
        if schedule = @schedules[class_name]
          Schedule.enqueue(schedule, start_time)
        end
      end
    end
  end
end
