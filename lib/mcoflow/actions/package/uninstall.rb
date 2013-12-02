module Mcoflow
  module Actions
    module Package
      class Uninstall < Mcoflow::Action

        input_format do
          param :package, String
        end

        def mco_agent
          :package
        end

        def mco_action
          :uninstall
        end

        def mco_args
          { :package => input[:package] }
        end

      end
    end
  end
end
