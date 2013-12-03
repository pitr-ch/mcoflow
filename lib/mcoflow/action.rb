module Mcoflow
  class Action < Dynflow::Action
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

    def run
      self.output[:request_id] = Mcoflow.connector.mco_run(mco_filter,
                                                           mco_agent,
                                                           mco_action,
                                                           mco_args)
      suspend
    end

    # needed by dynflow suspend mechanism
    def setup_progress_updates(suspended_action)
      Mcoflow.connector.wait_for_task(suspended_action, output[:request_id])
    end

    # invoked by PollingService
    def update_progress(done, payload)
      output.update payload: payload
    end
  end
end
