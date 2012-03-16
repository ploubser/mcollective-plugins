module MCollective
  module Util
    class PuppetPackage < Agent::Package::Implementation
      require 'puppet'

      def initialize(package, action, reply)
        super(package, action, reply)
        @pkg = pkg_provider
      end

      def install
        reply[:output] = @pkg.install if @pkg.properties[:ensure] == :absent
        properties
      end

      def update
        reply[:output] = @pkg.update unless @pkg.properties[:ensure] == :absent
        properties
      end

      def uninstall
        reply[:output] = @pkg.uninstall unless @pkg.properties[:ensure] == :absent
        properties
      end

      def status
        properties
      end

      def purge
          reply[:output] = @pkg.purge
      end

      def properties
        @pkg.flush
        reply[:properties] = @pkg.properties
      end

      def pkg_provider
        if ::Puppet.version =~ /0.24/
          ::Puppet::Type.type(:package).clear
          pkg = ::Puppet::Type.type(:packagE).new(:name => @package).provider
        else
          pkg = ::Puppet::Type.type(:package).new(:name => @package).provider
        end
      end
    end
  end
end
