require 'sidekiq_schedulable/schedule'

module SidekiqSchedulable
  class Startup
    def self.schedule!(schedules, current_jobs)
      new(schedules, current_jobs).schedule!
    end

    def initialize(schedules, current_jobs)
      @schedules = schedules
      @current_jobs = current_jobs
    end

    def schedule!
      schedules.each do |worker_class, schedule|
        unless already_scheduled?(worker_class)
          time = Schedule.next_time(schedule[:at])
          worker = schedule[:worker]
          worker.perform_at(time)
        end
      end
    end

    private

    attr_reader :schedules, :current_jobs

    def already_scheduled?(worker_class)
      scheduled_jobs.any? do |job|
        job.item['class'] == worker_class
      end
    end

    def scheduled_jobs
      @scheduled_jobs ||= current_jobs.select do |job|
        job.item['schedule']
      end
    end
  end
end
