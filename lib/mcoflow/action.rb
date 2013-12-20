module Mcoflow
  class Action < Dynflow::Action
    Run  = Connectors::MCollective::Run
    Done = Connectors::MCollective::Done

    # what agent should be used for the action
    def mco_agent
      raise RuntimeError, "Not implemented"
    end

    # what mco action should be triggered
    def mco_action
      raise RuntimeError, "Not implemented"
    end

    # what args shlould be passed
    def mco_args
      raise RuntimeError, "Not implemented"
    end

    def mco_filter
      raise "input[:hostname] is expected" unless input[:hostname]
      { identity_filter: input[:hostname] }
    end

    def run(event = nil)
      case event
      when nil
        suspend do |suspended_action|
          self.output[:request_id] =
              Mcoflow.connector.
                  ask(Run[suspended_action, mco_filter, mco_agent, mco_action, mco_args]).
                  value
        end
      when Done
        output.update payload: event.payload
      when Cancel
        output.update payload:  nil,
                      canceled: true
      else
        "unrecognized event #{event}"
      end
    end
  end
end
