require './mcoflow'

map '/' do
  run Sinatra::Application
end

require 'dynflow/web_console'

dynflow_console = Dynflow::WebConsole.setup do
  set :world, WORLD
end

map '/dynflow' do
  run dynflow_console
end
