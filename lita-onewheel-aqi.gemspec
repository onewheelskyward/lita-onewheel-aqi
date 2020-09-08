Gem::Specification.new do |spec|
  spec.name          = 'lita-onewheel-aqi'
<<<<<<< Updated upstream
  spec.version       = '2.5.0'
=======
  spec.version       = '2.4.0'
>>>>>>> Stashed changes
  spec.authors       = ['Andrew Kreps']
  spec.email         = ['andrew.kreps@gmail.com']
  spec.description   = 'AQI data retrieval bot'
  spec.summary       = 'Reads the current AQI from aqicn.org and displays it.'
  spec.homepage      = 'https://github.com/onewheelskyward/lita-onewheel-aqi'
  spec.license       = 'MIT'
  spec.metadata      = { 'lita_plugin_type' => 'handler'}

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'lita', '~> 4.4'

  spec.add_development_dependency 'bundler', '~> 2'
  # spec.add_development_dependency 'pry-byebug', '~> 3.1'
  spec.add_development_dependency 'rack-test', '~> 0'
  spec.add_development_dependency 'rake', '~> 13'
  spec.add_development_dependency 'rspec', '~> 3'
  spec.add_development_dependency 'timecop', '~> 0'

  spec.add_runtime_dependency 'geocoder', '~> 1.2'
  spec.add_runtime_dependency 'rest-client', '~> 2'

  spec.add_development_dependency 'simplecov', '~> 0'
  spec.add_development_dependency 'coveralls', '~> 0'
end
