require 'rubygems'
require 'rake'
require 'echoe'

Echoe.new('rfc5322', '1.0.0') do |p|
    p.description    = "Converts tweets to email and back"
    p.url            = "http://github.com/lionicsheriff/rfc5322"
    p.author         = "Matthew Goodall"
    p.email          = "dogsaw+rfc5322@thecyberplains.com"
    p.ignore_pattern = ["pkg/*", "tmp/*", "script/*","*.gemspec"]
    p.dependencies = ["maildir","trollop","htmlentities","unicode","grackle","roauth"]
end
