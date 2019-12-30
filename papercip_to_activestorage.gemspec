Gem::Specification.new do |s|
  s.name        = 'paerclip_to_activestorage'
  s.version     = '1.0'
  s.date        = '2019-12-26'
  s.summary     = 'Paperclip to activestaorage migration library'
  s.description = 'Migrate paperclip data to active storage table'
  s.authors     = ['Prajil TP']
  s.email       = 'tpprajilkottur@gmail.com'
  s.files       = ['lib/paperclip_to_activestorage.rb', 'lib/paperclip_to_active_storage/configuration.rb']
  s.homepage    = 'https://github.com/prajiltp/paerclip-to-activestorage'
  s.license     = 'MIT'
  s.required_ruby_version = '>= 2.1.5'
  s.add_runtime_dependency 'pry'
  s.add_runtime_dependency 'activerecord'
  s.add_runtime_dependency 'aws-sdk-s3'
end
