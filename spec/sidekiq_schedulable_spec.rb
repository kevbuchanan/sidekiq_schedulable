require 'sidekiq_schedulable'
require 'sidekiq'
require 'sidekiq/testing'
require 'timecop'

describe SidekiqSchedulable do

  Sidekiq::Testing.fake!

  class TestWorker
    include Sidekiq::Worker
    include Sidekiq::Schedulable

    sidekiq_schedule '*/10 * * * * *'

    def perform
      :done
    end
  end

  class AnotherWorker
    include Sidekiq::Worker
    include Sidekiq::Schedulable

    sidekiq_schedule '0 12 * * * *', last_run: true

    def perform(last_run)
      Time.now - Time.at(last_run)
    end
  end

  let(:midnight) { Time.new(2015, 10, 1, 0, 0, 0) }
  let(:next_ten_minutes) { midnight + 10 * 60 }

  let(:schedules) {
    {
      'TestWorker' => {
        worker: TestWorker,
        at: '*/10 * * * * *',
        options: {}
      },
      'AnotherWorker' => {
        worker: AnotherWorker,
        at: '0 12 * * * *',
        options: { last_run: true }
      }
    }
  }

  before do
    Timecop.freeze(midnight)
  end

  after do
    Sidekiq::Worker.clear_all
  end

  it "adds the schedule to the schedules" do
    schedule = SidekiqSchedulable.schedules['TestWorker']

    expect(schedule[:at]).to eq('*/10 * * * * *')
    expect(schedule[:worker]).to eq(TestWorker)
    expect(schedule[:options]).to eq({})
  end

  describe SidekiqSchedulable::Middleware::Server do
    let(:worker) { TestWorker.new }
    let(:middleware) { SidekiqSchedulable::Middleware::Server.new(schedules) }

    it "ensures the job is re-enqueued for next time" do
      expect {
        middleware.call(worker, { 'scheduled' => true, 'class' => 'TestWorker' }, 'a_queue') do
          raise 'Error'
        end
      }.to raise_error RuntimeError, "Error"

      jobs = TestWorker.jobs

      expect(jobs.size).to eq(1)
      expect(jobs.first['at']).to eq(next_ten_minutes.to_f)
    end

    it "does not re-schedule if the job has no schedule" do
      middleware.call(worker, {}, 'a_queue') do
        true
      end

      expect(TestWorker.jobs.size).to eq(0)
    end

    it "adds the last_run argument based on the last job start time" do
      middleware.call(worker, { 'scheduled' => true, 'class' => 'AnotherWorker' }, 'a_queue') do
        true
      end

      expect(AnotherWorker.jobs.size).to eq(1)
      expect(AnotherWorker.jobs.first['args']).to eq([Time.now.to_f])
      expect { AnotherWorker.drain }.to_not raise_error
    end
  end

  describe SidekiqSchedulable::Middleware::Client do
    let(:middleware) { SidekiqSchedulable::Middleware::Client.new(schedules) }

    it "adds the schedule to the job item" do
      item = {}

      middleware.call('TestWorker', item, 'a queue', nil) do
        true
      end

      expect(item['scheduled']).to eq(true)
    end

    it "does not add the schedule if the worker has no schedule" do
      item = {}

      middleware.call('Array', item, 'a_queue', nil) do
        true
      end

      expect(item['schedule']).to be_nil
    end
  end

  describe SidekiqSchedulable::Startup do
    Job = Struct.new(:item)

    def current_jobs
      TestWorker.jobs.map { |item| Job.new(item) }
    end

    it "enqueues a job for the given worker on an empty queue" do
      SidekiqSchedulable::Startup.new(schedules, current_jobs).schedule!

      expect(TestWorker.jobs.size).to eq(1)
      expect(TestWorker.jobs.first['at']).to eq(next_ten_minutes.to_f)
    end

    it "adds the last_run argument based on the schedule" do
      last_run = midnight - 60 * 60 * 12

      SidekiqSchedulable::Startup.new(schedules, current_jobs).schedule!

      expect(AnotherWorker.jobs.size).to eq(1)
      expect(AnotherWorker.jobs.first['args']).to eq([last_run.to_f])
      expect { AnotherWorker.drain }.to_not raise_error
    end

    it "does not enqueue a duplicate job for the given worker" do
      SidekiqSchedulable::Startup.new(schedules, current_jobs).schedule!
      SidekiqSchedulable::Startup.new(schedules, current_jobs).schedule!

      expect(TestWorker.jobs.size).to eq(1)
    end
  end
end
