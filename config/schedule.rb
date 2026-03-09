set :output, "log/whenever.log"
set :environment, ENV.fetch("RAILS_ENV", "development")

set :job_template, "/bin/zsh -lc ':job'"

job_type :rails_runner_in_app,
         "export PATH=\"$HOME/.local/share/mise/shims:$HOME/.local/bin:$PATH\" && " \
         "cd :path && bundle exec rails runner -e :environment ':task' :output"

every 1.hour do
  rails_runner_in_app "HourlyBalanceSweepJob.perform_async"
end
