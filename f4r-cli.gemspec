lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'f4r/cli/version'

Gem::Specification.new do |spec|
  spec.name          = 'f4r-cli'
  spec.version       = F4R::CLI::VERSION
  spec.authors       = ['jpablobr']
  spec.email         = ['xjpablobrx@gmail.com']

  spec.summary       = 'CLI for F4R'
  spec.homepage      = 'https://github.com/jpablobr/f4r-cli'
  spec.license       = 'MIT'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = spec.homepage

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }

  spec.add_dependency 'thor', '~>0.19.4'
  spec.add_dependency 'hashie', '~> 3.6.0'
  spec.add_dependency 'csv', '~> 3.1.2'
  spec.add_dependency 'f4r', '~> 0.1.0'
  spec.add_dependency 'pry'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 12.3.3'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'minitest-autotest'
  spec.add_development_dependency 'minitest-line'
end
