require "bundler/gem_tasks"

task :default => :build

desc "Build the site"
task :build do
  system("bundle exec jekyll build")
end

desc "Build and serve the site locally"
task :serve do
  system("bundle exec jekyll serve --livereload")
end

desc "Clean build artifacts"
task :clean do
  system("bundle exec jekyll clean")
end
