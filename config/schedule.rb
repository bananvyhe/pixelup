set :output, "log/whenever.log"
env_name = ENV.fetch("RAILS_ENV", "development")
set :environment, env_name

set :job_template, "/bin/bash -lc ':job'"

env :RAILS_MASTER_KEY, ENV["RAILS_MASTER_KEY"] if ENV["RAILS_MASTER_KEY"] && !ENV["RAILS_MASTER_KEY"].empty?
env :JWT_SIGNING_KEY, ENV["JWT_SIGNING_KEY"] if ENV["JWT_SIGNING_KEY"] && !ENV["JWT_SIGNING_KEY"].empty?

job_type :rails_runner_in_app,
         "if [ \":environment\" = \"development\" ] || [ \":environment\" = \"test\" ]; then " \
         "export PATH=\"$HOME/.local/share/mise/shims:$HOME/.local/bin:$PATH\"; " \
         "else " \
         "export BUNDLE_PATH=\"${BUNDLE_PATH:-/usr/local/bundle}\"; " \
         "export GEM_HOME=\"${GEM_HOME:-/usr/local/bundle}\"; " \
         "export BUNDLE_WITHOUT=\"${BUNDLE_WITHOUT:-development:test}\"; " \
         "export PATH=\"/usr/local/bundle/bin:$PATH\"; " \
         "fi; " \
         "cd :path && bundle exec rails runner -e :environment ':task' :output"

interval_minutes =
  (ENV.fetch("BILLING_INTERVAL_MINUTES", nil) || (env_name == "development" ? 20 : 60)).to_i

every interval_minutes.minutes do
  rails_runner_in_app "HourlyBalanceSweepJob.perform_async"
end
