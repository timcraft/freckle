Gem::Specification.new do |s|
  s.name = 'noko'
  s.version = '2.0.0'
  s.license = 'MIT'
  s.platform = Gem::Platform::RUBY
  s.authors = ['Tim Craft']
  s.email = ['email@timcraft.com']
  s.homepage = 'https://github.com/timcraft/noko'
  s.description = 'Ruby client for the Noko API'
  s.summary = 'See description'
  s.files = Dir.glob('lib/**/*.rb') + %w(CHANGES.md LICENSE.txt README.md noko.gemspec)
  s.required_ruby_version = '>= 3.1.0'
  s.require_path = 'lib'
  s.metadata = {
    'homepage' => 'https://github.com/timcraft/noko',
    'source_code_uri' => 'https://github.com/timcraft/noko',
    'bug_tracker_uri' => 'https://github.com/timcraft/noko/issues',
    'changelog_uri' => 'https://github.com/timcraft/noko/blob/main/CHANGES.md'
  }
  s.add_dependency 'net-http'
  s.add_dependency 'json', '~> 2'
  s.add_dependency 'uri', '~> 1'
end
