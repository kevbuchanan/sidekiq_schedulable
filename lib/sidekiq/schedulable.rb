module Sidekiq
  module Schedulable
    def self.included(klass)
      klass.extend(ClassMethods)
    end

    module ClassMethods
      def sidekiq_schedule(schedule)
        SidekiqSchedulable.schedules[self.to_s] = {
          worker: self,
          at: schedule
        }
      end
    end
  end
end
