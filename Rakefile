# -*- ruby -*-

require 'rubygems'
require 'hoe'

Hoe.plugin :isolate
Hoe.plugin :minitest

Hoe.plugin :version, :git

Hoe.spec 'rack-cas_client' do
  developer 'Brian Henderson', 'henderson.bj@gmail.com'

  self.readme_file      = "README.rdoc"

  self.testlib          = :minitest

  extra_deps << ['rack']
  extra_deps << ['rubycas-client']
  extra_dev_deps << ['rack-test']
end

# vim: syntax=ruby
