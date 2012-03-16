module MCollective
  module Util
    class PuppetPackage

      attr_accessor :package, :action, :reply

      def initialize(package, action, reply)
        raise "error. puppet not installed" unless check_dependencies
        @package = package
        @action = action
        @reply = reply
      end

      def do_pkg_action
        pkg = package_provider

        case action
          when :install
            reply[:output] = pkg.install if pkg.properties[:ensure] == :absent
          when :update
            reply[:output] = pkg.update unless pkg.properties[:ensure] == :absent
          when :uninstall
            reply[:output] = pkg.uninstall unless pkg.properties[:ensure] == :absent
          when :status
            pkg.flush
            reply[:output] = pkg.properties
          when :purge
            reply[:output] = pkg.purge
          else
            reply.fail "Unknown action #{@action}"
        end

        pkg.flush
        reply[:properties] = pkg.properties

      end

      def package_provider
        if ::Puppet.version =~ /0.24/
          ::Puppet::Type.type(:package).clear
          pkg = ::Puppet::Type.type(:packagE).new(:name => @package).provider
        else
          pkg = ::Puppet::Type.type(:package).new(:name => @package).provider
        end
      end

      def check_dependencies
        begin
          require 'puppet'
        rescue
          return false
        end
        return true
      end
    end
  end
end
