module Sidekiq
  module Schedulable
    def self.included(klass)
      klass.extend(ClassMethods)
    end

    module ClassMethods
      def sidekiq_schedule(schedule, options = {})
        SidekiqSchedulable.schedules[self.to_s] = {
          worker: self,
          at: schedule,
          options: options
        }
      end
    end
  end
end
