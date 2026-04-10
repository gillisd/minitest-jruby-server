require "minitest/test_task"

Minitest::TestTask.create :test do |t|
  t.test_globs = ["test/**/*test*.rb"]
  t.warning = true
end

task default: :test
