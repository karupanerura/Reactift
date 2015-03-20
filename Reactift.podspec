Pod::Spec.new do |s|
  s.name             = "Reactift"
  s.version          = "0.1.0"
  s.summary          = "Reactive Programming framework for Swift."
  s.description      = <<-DESC
                       Provides:
                       * ReactiveX like interface
                       * Support type safety by generics
                       * dispatch queue based scheduler.
                       DESC
  s.homepage         = "https://github.com/karupanerura/Reactift"
  s.license          = 'MIT'
  s.author           = { "karupanerura" => "karupa@cpan.org" }
  s.source           = { :git => "https://github.com/karupanerura/Reactift.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/karupanerura'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Reactift/**/*.{swift,h}'
end
