require 'parse-cron'

module SidekiqSchedulable
  module Schedule
    def self.next_time(schedule)
      CronParser.new(schedule).next(Time.now)
    end
  end
end
