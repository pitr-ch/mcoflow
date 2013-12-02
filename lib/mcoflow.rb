require 'dynflow'
require 'mcollective'
require 'logger'

require 'mcoflow/connectors/mcollective'
require 'mcoflow/action'
Dir.glob(File.expand_path('../mcoflow/actions/**/*.rb', __FILE__)) { |f| require f }

module Mcoflow

  def self.initialize_mcollective(configfile)
    if MCollective::Config.instance.configured
      raise 'Mcollective configuration is already initialized'
    else
      MCollective::Config.instance.loadconfig(configfile)
    end
    @connector = Mcoflow::Connectors::MCollective.new(Logger.new($stderr))
  end

  def self.connector
    unless @connector
      raise 'One needs to run intialize_mcollective first'
    end
    @connector
  end

end
