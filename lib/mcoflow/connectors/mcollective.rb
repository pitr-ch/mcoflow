module Mcoflow
  module Connectors
    class MCollective < Dynflow::MicroActor

      include ::MCollective::RPC

      REPLY_QUEUE = '/queue/mcollective.mcoflow'

      Task = Algebrick.type do
        fields(action:       Dynflow::Action::Suspended,
               request_id:   String)
      end

      Response = Algebrick.type do
        fields(request_id:   String,
               payload:      Hash)
      end

      def initialize(logger)
        super(logger)
        @tasks   =  {}
        @mcollective_mutex = Mutex.new

        stomp_connection.subscribe(REPLY_QUEUE, { :id => 1 })

        @listener = Thread.new do
          loop do
            begin
              raw_msg = stomp_connection.receive
              message  = ::MCollective::Message.new(raw_msg.body, raw_msg)
              message.type = :reply
              message.decode!
              self << Response[message.requestid, message.payload]
            rescue => e
              puts "Error #{e.message}"
              puts e.backtrace.join("\n")
            end
          end
        end
      end

      # Initiate the mcollective action
      def mco_run(mco_filters, mco_agent, mco_action, mco_args)
        # RPC client is not thread safe, make sure we connect with only one instance
        # at a time
        @mcollective_mutex.synchronize do
          client = rpcclient(mco_agent.to_s,
                             :options => ::MCollective::Util.default_options)
          mco_filters.each do |key, value|
            client.send(key, *Array(value))
          end
          client.reply_to = REPLY_QUEUE
          request_id = client.send(mco_action, mco_args)
          client.disconnect
          request_id
        end
      end

      # register an action for resuming: this is the time when the task
      # is delegated to mcollective and we wait for it to finish on message bus
      def wait_for_task(action, request_id)
        # simulate polling for the state of the external task
        self << Task[action, request_id]
      end

      private

      def load_stomp_config
        ::MCollective::Config.instance.pluginconf.reduce({}) do |h, (k, v)|
          (key = k[/^activemq.*\.(\w+)$/,1]) ? h.update(key => v) : h
        end
      end

      def stomp_connection
        return @connection if @connection
        stomp_config = load_stomp_config
        config = {:hosts => [{ :login => stomp_config["user"],
                               :passcode => stomp_config["password"],
                               :host => stomp_config["host"],
                               :port => stomp_config["port"] }]}
        @connection = Stomp::Connection.open(config)
      end

      def on_message(message)
        case message
        when Task
          if @tasks.has_key?(message[:request_id])
            raise "The task #{message[:request_id]} is already watched"
          end
          @tasks[message[:request_id]] = message
        when Response
          resume_action(message)
        end
      end

      def resume_action(response)
        task = @tasks[response[:request_id]]
        unless task
          raise "we were not able to update a task #{response[:request_id]}"
        end
        task[:action].update_progress(true, response[:payload])
        @tasks.delete(response[:request_id])
      end

    end

  end
end
