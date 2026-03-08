redis_url = ENV.fetch("REDIS_URL", "redis://127.0.0.1:6379/0")

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }

  begin
    require "sidekiq/cron/job"
    Sidekiq::Cron::Job.load_from_hash!(
      "hourly_balance_sweep" => {
        "class" => "HourlyBalanceSweepJob",
        "cron" => "0 * * * *",
        "queue" => "default",
        "description" => "Hourly balance deduction for active billable users"
      }
    )
  rescue LoadError
    Rails.logger.warn("sidekiq-cron is not available; hourly schedule was not registered")
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end
