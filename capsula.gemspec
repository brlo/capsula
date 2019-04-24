Gem::Specification.new do |s|
  s.name        = 'capsula'
  s.version     = '0.0.3'
  s.date        = '2019-02-04'
  s.summary     = 'Encapsulating tool'
  s.description = 'The tool for encapsulating (preloading, including) related objects'
  s.authors     = ['Rodion V']
  s.email       = 'rodion.v@devaer.com'
  s.homepage    = 'https://github.com/brlo/capsula'
  s.license     = 'MIT'

  all_files     = `git ls-files`.split("\n")
  test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")

  s.files         = all_files - test_files
  s.test_files    = test_files
  s.require_paths = ['lib']
end
