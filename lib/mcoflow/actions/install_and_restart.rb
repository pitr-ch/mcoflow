module Mcoflow
  module Actions

    class InstallAndRestart < Dynflow::Action

      def plan(packages, services)
        package_actions = packages.map do |package|
          plan_action(Package::Install,
                      package: package)
        end
        services.each do |service|
          plan_action(Service::Restart,
                      service: service,
                      installations: package_actions.map(&:output))
        end
      end
    end
  end
end
