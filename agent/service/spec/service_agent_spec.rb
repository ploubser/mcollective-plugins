#!/usr/bin/env rspec
require 'spec_helper'

describe "service agent" do
  before do
    agent_file = File.join([File.dirname(__FILE__), "../agent/service.rb"])
    @agent = MCollective::Test::LocalAgentTest.new("service", :agent_file => agent_file).plugin
  end

  describe "#meta" do
    it "should have valid metadata" do
      @agent.should have_valid_metadata
    end
  end

  describe "#do_service_action" do
    before(:each) do
      @agent.config.stubs(:pluginconf).returns("service.provider" => "testprovider")
      @provider = mock
      @provider.stubs(:new).returns(@provider)
    end

    it "should load the service provider specified in pluginconf" do
      @provider.expects(:send).with("status")
      MCollective::PluginManager.expects(:loadclass).with("MCollective::Util::TestproviderService")
      MCollective::Util.expects(:const_get).with("TestproviderService").returns(@provider)
      result = @agent.call(:status, :service => "puppet")
      result.should be_successful
    end

    it "should fail if specified service provider is not present" do
      result = @agent.call(:status, :service => "puppet")
      result.should be_aborted_error
    end

    it "should fail if an action hasn't been implemented by the implementation class" do
      class TestService < MCollective::Agent::Service::Implementation
      end

      MCollective::PluginManager.expects(:loadclass).with("MCollective::Util::TestproviderService")
      MCollective::Util.expects(:const_get).with("TestproviderService").returns(TestService)
      result = @agent.call(:status, :service => "puppet")
      result.should be_aborted_error
      result[:statusmsg].should == "error. status action has not been implemented"
    end

    it "should call the providers $action method if it has been implemented" do
      class TestService < MCollective::Agent::Service::Implementation
        def status
          reply[:output] = "Status call was successful"
        end
      end

      MCollective::PluginManager.expects(:loadclass).with("MCollective::Util::TestproviderService")
      MCollective::Util.expects(:const_get).with("TestproviderService").returns(TestService)
      result = @agent.call(:status, :service => "puppet")
      result.should be_successful
      result.should have_data_items(:output => "Status call was successful")
    end
  end
end
