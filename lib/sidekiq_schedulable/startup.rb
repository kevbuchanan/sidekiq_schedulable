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
      schedules.each do |klass_name, schedule|
        unless already_scheduled?(klass_name)
          Schedule.enqueue(schedule)
        end
      end
    end

    private

    attr_reader :schedules, :current_jobs

    def already_scheduled?(klass_name)
      scheduled_jobs.any? do |job|
        job.item['class'] == klass_name
      end
    end

    def scheduled_jobs
      @scheduled_jobs ||= current_jobs.select do |job|
        job.item['scheduled']
      end
    end
  end
end
