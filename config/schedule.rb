set :output, "log/whenever.log"
set :environment, ENV.fetch("RAILS_ENV", "development")

set :job_template, "/bin/bash -lc ':job'"

job_type :rails_runner_in_app,
         "export BUNDLE_PATH=\"${BUNDLE_PATH:-/usr/local/bundle}\"; " \
         "export GEM_HOME=\"${GEM_HOME:-/usr/local/bundle}\"; " \
         "export PATH=\"/usr/local/bundle/bin:$PATH\"; " \
         "if [ -d \"$HOME/.local/share/mise/shims\" ]; then " \
         "export PATH=\"$HOME/.local/share/mise/shims:$HOME/.local/bin:$PATH\"; " \
         "fi; " \
         "cd :path && bundle exec rails runner -e :environment ':task' :output"

every 1.hour do
  rails_runner_in_app "HourlyBalanceSweepJob.perform_async"
end
