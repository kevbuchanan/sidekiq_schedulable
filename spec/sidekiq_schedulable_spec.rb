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
  end

  let(:midnight) { Time.new(2015, 10, 1, 0, 0, 0) }
  let(:next_ten_minutes) { midnight + 10 * 60 }

  before do
    Timecop.freeze(midnight)
  end

  after do
    TestWorker.jobs.clear
  end

  it "adds the schedule to the schedules" do
    schedule = SidekiqSchedulable.schedules["TestWorker"]

    expect(schedule[:at]).to eq('*/10 * * * * *')
    expect(schedule[:worker]).to eq(TestWorker)
  end

  describe SidekiqSchedulable::Middleware::Server do
    let(:worker) { TestWorker.new }
    let(:middleware) { SidekiqSchedulable::Middleware::Server.new }

    it "ensures the job is re-enqueued for next time" do
      expect {
        middleware.call(worker, { 'schedule' => '*/10 * * * * *' }, 'a queue') do
          raise "Error"
        end
      }.to raise_error RuntimeError, "Error"

      jobs = TestWorker.jobs

      expect(jobs.size).to eq(1)
      expect(jobs.first['at']).to eq(next_ten_minutes.to_f)
    end

    it "does not re-schedule if the job has no schedule" do
      middleware.call(worker, {}, 'a queue') do
        true
      end

      expect(TestWorker.jobs.size).to eq(0)
    end
  end

  let(:schedules) {
    { "TestWorker" => { worker: TestWorker, at: '*/10 * * * * *' } }
  }

  describe SidekiqSchedulable::Middleware::Client do
    let(:middleware) { SidekiqSchedulable::Middleware::Client.new(schedules) }

    it "adds the schedule to the job item" do
      item = {}

      middleware.call("TestWorker", item, "a queue", nil) do
        true
      end

      expect(item['schedule']).to eq('*/10 * * * * *')
    end

    it "does not add the schedule if the worker has no schedule" do
      item = {}

      middleware.call("Array", item, "a queue", nil) do
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
      SidekiqSchedulable::Startup.schedule!(schedules, current_jobs)

      expect(TestWorker.jobs.size).to eq(1)
      expect(TestWorker.jobs.first['at']).to eq(next_ten_minutes.to_f)
    end

    it "does not enqueue a duplicate job for the given worker" do
      SidekiqSchedulable::Startup.schedule!(schedules, current_jobs)
      SidekiqSchedulable::Startup.schedule!(schedules, current_jobs)

      expect(TestWorker.jobs.size).to eq(1)
    end
  end
end
