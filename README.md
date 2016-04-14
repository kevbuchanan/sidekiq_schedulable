[![Gem Version](https://badge.fury.io/rb/sidekiq_schedulable.svg)](https://badge.fury.io/rb/sidekiq_schedulable)

# Sidekiq Schedulable

Schedule Cron style Sidekiq jobs

## Usage

```ruby
require 'sidekiq_schedulable'
```

```ruby
class MyJob
  include Sidekiq::Worker
  include Sidekiq::Schedulable

  sidekiq_options retry: false, queue: 'my_scheduled_jobs_queue'
  sidekiq_schedule '*/5 * * * * *'

  def perform
    RunReport.call
  end
end
```

Using the last run time:

```ruby
class MyJob
  include Sidekiq::Worker
  include Sidekiq::Schedulable

  sidekiq_options retry: false, queue: 'my_scheduled_jobs_queue'
  sidekiq_schedule '*/5 * * * * *', last_run: true

  def perform(last_run)
    RunReport.between(Time.at(last_run), Time.now)
  end
end
```
