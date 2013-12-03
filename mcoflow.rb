require 'sinatra'
require 'mcollective'
require 'pry'

$:.unshift(File.expand_path('../lib', __FILE__))
require 'mcoflow'

Mcoflow.initialize_mcollective(File.expand_path('~/.mcollective'))

dynflow_config = {}
dynflow_config[:persistence_adapter] =  Dynflow::PersistenceAdapters::Sequel.new('sqlite://db/mcoflow.sqlite')
WORLD = Dynflow::SimpleWorld.new(dynflow_config)

helpers ERB::Util

get '/' do
  @uuid = params[:uuid]
  erb :index
end

post '/trigger' do
  task = case params[:action].to_s.downcase
            when "install"
              WORLD.trigger(Mcoflow::Actions::Package::Install,
                            :package => params[:param])
            when "uninstall"
              WORLD.trigger(Mcoflow::Actions::Package::Uninstall,
                            :package => params[:param])
            when "restart"
              WORLD.trigger(Mcoflow::Actions::Service::Restart,
                            :service => params[:param])
            when "install_and_restart"
              packages, services = params[:param].split(';')
              packages = packages.split(',').map(&:strip)
              services = services.split(',').map(&:strip)
              WORLD.trigger(Mcoflow::Actions::InstallAndRestart,
                            packages, services)
            else
              raise "unkown action #{params[:action]}"
         end
  redirect "/?uuid=#{task.id}"
end
