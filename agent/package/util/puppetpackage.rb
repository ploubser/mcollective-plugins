module MCollective
  module Util
    class PuppetPackage < Agent::Package::Implementation
      require 'puppet'
      # Implementation of a puppet package provider.
      # The [install|update|uninstall|status|purge] purge methods
      # override these defined in Agent::Package::Implementation.
      def install
        reply[:output] = pkg_provider.install if pkg_provider.properties[:ensure] == :absent
        properties
      end

      def update
        reply[:output] = pkg_provider.update unless pkg_provider.properties[:ensure] == :absent
        properties
      end

      def uninstall
        reply[:output] = pkg_provider.uninstall unless pkg_provider.properties[:ensure] == :absent
        properties
      end

      def status
        properties
      end

      def purge
          reply[:output] = pkg_provider.purge
      end

      def properties
        pkg_provider.flush
        reply[:properties] = pkg_provider.properties
      end

      def pkg_provider
        @pkg ||= ::Puppet::Type.type(:package).new(:name => @package).provider
      end
    end
  end
end
