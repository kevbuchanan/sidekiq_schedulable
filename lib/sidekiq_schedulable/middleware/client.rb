module SidekiqSchedulable
  module Middleware
    class Client
      def initialize(schedules = {})
        @schedules = schedules
      end

      def call(worker_class, item, queue, redis_pool)
        if schedule = @schedules[worker_class]
          item['schedule'] = schedule[:at]
        end
        yield
      end
    end
  end
end
