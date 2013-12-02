Gem::Specification.new do |s|
  s.name = "mcoflow"
  s.version = "0.0.1"

  s.authors = ["Ivan Necas"]
  s.date = Time.now.strftime("%Y-%m-%d")
  s.description = "MCollective over Dynflow"
  s.email = "inecas@redhat.com"
  s.files = %w(Gemfile mcoflow.gemspec MIT-LICENSE README.md)
  s.files += Dir["lib/**/*.rb"]
  s.homepage = "http://github.com/katello/katello-foreman-engine"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.add_dependency "mcollective-client"
  s.add_dependency "dynflow"
  s.add_dependency "stomp", "~> 1.2.16" # later version has some issues with ActiveMQ
  s.summary = "MCollective orchestrating using Dynflow engine"
end
