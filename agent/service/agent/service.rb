require 'puppet'

module MCollective
  module Agent
    # An agent that uses Puppet to manage services
    #
    # See https://github.com/puppetlabs/mcollective-plugins
    #
    # Released under the terms of the Apache Software License, v2.0.
    #
    # As this agent is based on Simple RPC, it requires mcollective 0.4.7 or newer.
    class Service<RPC::Agent
      class Implementation
        attr_accessor :service, :reply, :hasrestart, :hasstatus

        def initialize(service, reply, hasrestart, hasstatus)
          @service = service
          @hasrestart = hasrestart
          @hasstatus = hasstatus
          @reply = reply
        end

        [:stop, :start, :restart, :status].each do |act|
          define_method act do
            reply.fail "error. #{act} action has not been implemented"
          end
        end
      end

      metadata    :name        => "Service Agent",
                  :description => "Start and stop system services",
                  :author      => "R.I.Pienaar",
                  :license     => "ASL2",
                  :version     => "2.0",
                  :url         => "https://github.com/puppetlabs/mcollective-plugins",
                  :timeout     => 60

      ["stop", "start", "restart", "status"].each do |act|
        action act do
          do_service_action(act)
        end
      end

      private
      # Does the actual work with the service provider and sets appropriate reply options
      def do_service_action(action)
        validate :service, String

        hasrestart = false
        hasstatus = false
        service = request[:service]

        begin
          Log.instance.debug("Doing #{action} for service #{service}")

          if @config.pluginconf.include?("service.hasrestart")
            hasrestart = true if @config.pluginconf["service.hasrestart"] =~ /^1|y|t/
          end

          if @config.pluginconf.include?("service.hasstatus")
            hasstatus = true if @config.pluginconf["service.hasstatus"] =~ /^1|y|t/
          end

          service_provider = @config.pluginconf["service.provider"]
          PluginManager.loadclass("MCollective::Util::#{service_provider.capitalize}Service")
          svc = Util.const_get("#{service_provider.capitalize}Service").new(service, reply, hasrestart, hasstatus)
          svc.send action

        rescue Exception => e
          reply.fail "#{e}"
        end
      end
    end
  end
end

# vi:tabstop=2:expandtab:ai:filetype=ruby
