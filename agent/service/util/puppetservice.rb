module MCollective
  module Util
    class PuppetService < Agent::Service::Implementation
      require 'puppet'

      def stop
        service_provider.stop
        properties
      end

      def start
        service_provider.start
        properties
      end

      def restart
        if @hasrestart
          service_provider.restart
          properties
        else
          raise "service 'hassrestart' is not defined in server.cfg"
        end
      end

      def status
        if @hasstatus
          reply["status"] = service_provider.status.to_s
        else
          raise "service 'hasstatus' is not defined in server.cfg"
        end
      end

      def service_provider
        @svc ||= ::Puppet::Type.type(:service).new(:name => @service, :hasstatus => @hasstatus,  :hasrestart => @hasrestart).provider
      end

      def properties
        sleep 0.5
        status
      end
    end
  end
end
