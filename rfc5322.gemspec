# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rfc5322}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Matthew Goodall"]
  s.cert_chain = ["/Users/matt/.ssh/gem-public_cert.pem"]
  s.date = %q{2010-09-07}
  s.description = %q{Converts tweets to email and back}
  s.email = %q{dogsaw+rfc5322@nospam@thecyberplains.com}
  s.executables = ["fetchtweet", "sendtweet"]
  s.extra_rdoc_files = ["README", "bin/fetchtweet", "bin/sendtweet", "lib/oauth_key.rb", "lib/rfc5322.rb"]
  s.files = ["Manifest", "README", "Rakefile", "bin/fetchtweet", "bin/sendtweet", "lib/oauth_key.rb", "lib/rfc5322.rb", "rfc5322.gemspec"]
  s.homepage = %q{http://github.com/lionicsheriff/rfc5322}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Rfc5322", "--main", "README"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{rfc5322}
  s.rubygems_version = %q{1.3.7}
  s.signing_key = %q{/Users/matt/.ssh/gem-private_key.pem}
  s.summary = %q{Converts tweets to email and back}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
