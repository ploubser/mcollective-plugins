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
        service_provider.restart
        properties
      end

      def status
        reply["status"] = service_provider.status.to_s
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
