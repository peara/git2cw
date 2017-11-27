task default: %w[build start]

task :build do
  sh "bundle install"
end

task :start do
  ruby "app/main.rb"
end
