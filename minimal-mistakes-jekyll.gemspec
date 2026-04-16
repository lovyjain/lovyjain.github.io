# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "lovyjain-github-io"
  spec.version       = "1.0.0"
  spec.authors       = ["Lovy Jain"]
  spec.email         = ["lovyjain18@gmail.com"]

  spec.summary       = "Lovy Jain — Technical Architect & AI Solutions Specialist"
  spec.homepage      = "https://lovyjain.github.io"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").select do |f|
    f.match(%r{^(assets|_(includes|layouts|sass)/|(LICENSE|README)((\.(txt|md|markdown)|$)))}i)
  end

  spec.add_runtime_dependency "jekyll", ">= 3.6", "< 5.0"
  spec.add_runtime_dependency "minimal-mistakes-jekyll"
  spec.add_runtime_dependency "jekyll-paginate", "~> 1.1"
  spec.add_runtime_dependency "jekyll-sitemap", "~> 1.3"
  spec.add_runtime_dependency "jekyll-gist", "~> 1.5"
  spec.add_runtime_dependency "jekyll-feed", "~> 0.1"
  spec.add_runtime_dependency "jekyll-include-cache", "~> 0.1"
  spec.add_runtime_dependency "jekyll-seo-tag"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 12.3"
end
