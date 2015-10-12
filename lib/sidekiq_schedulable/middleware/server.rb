require 'sidekiq_schedulable/schedule'

module SidekiqSchedulable
  module Middleware
    class Server
      def call(worker, item, queue)
        yield
      ensure
        schedule_next_job(worker, item) if item['schedule']
      end

      private

      def schedule_next_job(worker, item)
        schedule = item['schedule']
        time = Schedule.next_time(schedule)
        worker.class.perform_at(time)
      end
    end
  end
end
