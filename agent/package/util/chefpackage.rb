module MCollective
  module Util
    class RPMPackage

      attr_accessor :package, :action, :reply

      def initialize(package, action, reply)
        @package = package
        @action = action
        @reply = reply
      end

      def do_pkg_action
        reply[:properties]= {:arch => "x86_64",
                             :provider => "yum",
                             :epoc => "0",
                             :version => "0.0.0",
                             :ensure => "absent",
                             :release => "fake",
                             :name => package}
        case action
          when :install
            reply[:output] = "Doing the rpm pseudo install of package #{package}"
            reply[:properties] = {}
          when :update
            reply[:output] = "Doing the rpm pseudo update of package #{package}"
          when :uninstall
            reply[:output] = "Doing the rpm pseudo uninstall of package #{package}"
          when :purge
            reply[:output] = "Doing the rpm pseudo purge of package #{package}"
          when :status
            reply[:output] = "This is pakcage #{package}'s status from the rpm package provider"
          else
            reply.fail = "Unkown action, #{action}"
        end
      end

    end
  end
end
