module Mcoflow
  module Actions

    class InstallAndRestart < Dynflow::Action

      def plan(hostname, packages, services)
        package_actions = packages.map do |package|
          plan_action(Package::Install,
                      hostname: hostname,
                      package: package)
        end
        services.each do |service|
          plan_action(Service::Restart,
                      hostname: hostname,
                      service: service,
                      installations: package_actions.map(&:output))
        end
      end
    end
  end
end
