#!/usr/bin/env rspec
require 'spec/spec_helper'
require File.join(File.dirname(__FILE__), "../agent/service.rb")
require File.join(File.dirname(__FILE__), "../util/puppetservice.rb")

module MCollective
  module Util
    describe PuppetService do

      describe "Service Provider" do
       it "should create an instance of the puppet service provider" do
         provider = MCollective::Util::PuppetService.new("service", {}, false, false)
         provider.service_provider.class.to_s.should match(/Puppet::Type::Service::Provider/)
       end

       it "should only create one instance of the puppet service provider" do
         provider = MCollective::Util::PuppetService.new("service", {}, false, false)
         id = provider.service_provider.object_id
         id.should == provider.service_provider.object_id
       end
      end

      describe "Service Actions" do
        before do
          @provider = mock
          @service = MCollective::Util::PuppetService.new("service", {:status => nil}, true, true)
          @service.stubs(:service_provider).returns(@provider)
        end

        it "should stop the service" do
          @provider.expects(:stop)
          @service.expects(:sleep).with(0.5)
          @provider.expects(:status).returns("stopped")
          @service.stop
          @service.reply["status"].should == "stopped"
        end

        it "should start the service" do
          @provider.expects(:start)
          @service.expects(:sleep).with(0.5)
          @provider.expects(:status).returns("started")
          @service.start
          @service.reply["status"].should == "started"
        end

        it "should restart the service if hasrestart is true" do
          @provider.expects(:restart)
          @service.expects(:sleep).with(0.5)
          @provider.expects(:status).returns("restarted")
          @service.restart
          @service.reply["status"].should == "restarted"
        end

        it "should not restart the service is hasrestart is false" do
          @provider.expects(:restart).never
          @service.hasrestart = false
          expect{
            @service.restart
          }.to raise_error RuntimeError
        end

        it "should return the status of the service if hasstatus is true" do
          @provider.expects(:status).returns("status")
          @service.status
          @service.reply["status"].should == "status"
        end

        it "should not return the status of the service if hasstatus is false" do
          @provider.expects(:status).never
          @service.hasstatus = false
          expect{
            @service.status
          }.to raise_error RuntimeError
        end
      end
    end
  end
end

