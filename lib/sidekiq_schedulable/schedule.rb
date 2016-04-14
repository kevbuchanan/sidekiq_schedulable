require 'parse-cron'

module SidekiqSchedulable
  module Schedule
    def self.enqueue(schedule, last_run = nil)
      return if schedule[:crons].empty?

      worker = schedule[:worker]
      schedule[:crons].each do |cron|
        time = next_time(cron)
        if schedule[:options][:last_run]
          last_time = last_run || last_time(cron)
          worker.perform_at(time, last_time.to_f)
        else
          worker.perform_at(time)
        end
      end
    end

    def self.next_time(schedule)
      CronParser.new(schedule).next(Time.now)
    end

    def self.last_time(schedule)
      CronParser.new(schedule).last(Time.now)
    end
  end
end
