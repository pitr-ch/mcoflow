module Mcoflow
  module Connectors
    class MCollective < Dynflow::MicroActor

      include ::MCollective::RPC

      REPLY_QUEUE = '/queue/mcollective.mcoflow'

      Response = Algebrick.type do
        fields! request_id: String,
                payload:    Hash
      end

      Run = Algebrick.type do
        fields! action:      Dynflow::Action::Suspended,
                mco_filters: Hash,
                mco_agent:   Symbol,
                mco_action:  Symbol,
                mco_args:    Array
      end

      Done = Algebrick.type { fields! payload: Hash }

      def initialize(logger)
        super(logger)
        @suspended_actions = {}
        stomp_connection.subscribe(REPLY_QUEUE, { :id => 1 })

        @listener = Thread.new do
          loop do
            begin
              raw_msg      = stomp_connection.receive
              message      = ::MCollective::Message.new(raw_msg.body, raw_msg)
              message.type = :reply
              message.decode!
              self << Response[message.requestid, message.payload]
            rescue => e
              logger.error "Error #{e.message} (#{e.class})\n#{e.backtrace.join("\n")}"
            end
          end
        end
      end

      private

      def load_stomp_config
        ::MCollective::Config.instance.pluginconf.each_with_object({}) do |(k, v), h|
          key = k[/^activemq.*\.(\w+)$/, 1]
          h.update(key => v) if key
        end
      end

      def stomp_connection
        @connection ||= begin
          stomp_config = load_stomp_config
          config       = { :hosts => [{ :login    => stomp_config["user"],
                                        :passcode => stomp_config["password"],
                                        :host     => stomp_config["host"],
                                        :port     => stomp_config["port"] }] }
          Stomp::Connection.open(config)
        end
      end

      def on_message(message)
        match(message,

              on(~Response) do |response|
                suspended_action = @suspended_actions.delete(response.request_id)
                raise "we were not able to update a task #{response.request_id}" unless suspended_action
                suspended_action << Done[response.payload]
              end,

              on(~Run) do |(suspended_action, *mco_run_args)|
                request_id                     = mco_run(*mco_run_args)
                @suspended_actions[request_id] = suspended_action
                request_id
              end)
      end

      # Initiate the mcollective action
      def mco_run(mco_filters, mco_agent, mco_action, mco_args)
        client = rpcclient(mco_agent.to_s,
                           :options => ::MCollective::Util.default_options)
        mco_filters.each do |key, value|
          client.send(key, *Array(value))
        end
        client.reply_to = REPLY_QUEUE
        client.send(mco_action, mco_args) # => request_id
      ensure
        client.disconnect
      end
    end

  end
end
