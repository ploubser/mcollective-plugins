#!/usr/bin/env rspec
require 'spec_helper'

describe "package agent" do
  before do
    agent_file = File.join([File.dirname(__FILE__), "../agent/package.rb"])
    @agent = MCollective::Test::LocalAgentTest.new("package", :agent_file => agent_file).plugin
  end
  after :all do
    MCollective::PluginManager.clear
  end

  describe "#yum_clean" do
    it "should fail if /usr/bin/yum doesn't exist" do
      File.expects(:exist?).with("/usr/bin/yum").returns(false)
      result = @agent.call(:yum_clean)
      result.should be_aborted_error
      result[:statusmsg].should == "Cannot find yum at /usr/bin/yum"
    end

    it "should succeed if run method returns 0" do
      File.expects(:exist?).with("/usr/bin/yum").returns(true)
      @agent.config.expects(:pluginconf).returns({"package.yum_clean_mode" => "all"})
      @agent.expects(:run).with("/usr/bin/yum clean all", :stdout => :output, :chomp => true).returns(0)

      result = @agent.call(:yum_clean)
      result.should be_successful
      result.should have_data_items(:exitcode => 0)
    end

    it "should fail if the run method doesn't return 0" do
      File.expects(:exist?).with("/usr/bin/yum").returns(true)
      @agent.expects(:run).with("/usr/bin/yum clean all", :stdout => :output, :chomp => true).returns(1)
      @agent.config.expects(:pluginconf).returns({"package.yum_clean_mode" => "all"})
      result = @agent.call(:yum_clean)
      result.should be_aborted_error
      result.should have_data_items(:exitcode => 1)
    end

    it "should default to 'all' mode" do
      File.expects(:exist?).with("/usr/bin/yum").returns(true)
      @agent.config.expects(:pluginconf).returns({})
      @agent.expects(:run).with("/usr/bin/yum clean all", :stdout => :output, :chomp => true).returns(0)

      result = @agent.call(:yum_clean)
      result.should be_successful
      result.should have_data_items(:exitcode => 0)
    end

    it "should support a configured mode" do
      File.expects(:exist?).with("/usr/bin/yum").returns(true)
      @agent.config.expects(:pluginconf).returns({"package.yum_clean_mode" => "headers"})
      @agent.expects(:run).with("/usr/bin/yum clean headers", :stdout => :output, :chomp => true).returns(0)

      result = @agent.call(:yum_clean)
      result.should be_successful
      result.should have_data_items(:exitcode => 0)
    end

    it "should support configured modes" do
      ["all", "headers", "packages", "metadata", "dbcache", "plugins", "expire-cache"].each do |mode|
        File.expects(:exist?).with("/usr/bin/yum").returns(true)
        @agent.config.expects(:pluginconf).returns({"package.yum_clean_mode" => "all"})
        @agent.expects(:run).with("/usr/bin/yum clean #{mode}", :stdout => :output, :chomp => true).returns(0)

        result = @agent.call(:yum_clean, :mode => mode)
        result.should be_successful
        result.should have_data_items(:exitcode => 0)
      end
    end
  end

  describe "#apt_update" do
    it "should fail if /usr/bin/apt-get doesn't exist" do
      File.expects(:exist?).with("/usr/bin/apt-get").returns(false)
      result = @agent.call(:apt_update)
      result.should be_aborted_error
      result[:statusmsg].should == "Cannot find apt-get at /usr/bin/apt-get"
    end

    it "should succeed if the agent responds to 'run' and the run method returns 0" do
      File.expects(:exist?).with("/usr/bin/apt-get").returns(true)
      @agent.expects(:run).with("/usr/bin/apt-get update", :stdout => :output, :chomp => true).returns(0)
      result = @agent.call(:apt_update)
      result.should have_data_items(:exitcode => 0)
      result.should be_successful
    end

    it "should fail if the agent responds to 'run' and the run method doesn't return 0" do
      File.expects(:exist?).with("/usr/bin/apt-get").returns(true)
      @agent.expects(:run).with("/usr/bin/apt-get update", :stdout => :output, :chomp => true).returns(1)
      result = @agent.call(:apt_update)
      result.should have_data_items(:exitcode => 1)
      result.should be_aborted_error
    end
  end

  describe "#checkupdates" do
    it "should fail if neither /usr/bin/yum or /usr/bin/apt-get are present" do
      File.expects(:exist?).with("/usr/bin/yum").returns(false)
      File.expects(:exist?).with("/usr/bin/apt-get").returns(false)
      result = @agent.call(:checkupdates)
      result.should be_aborted_error
      result[:statusmsg].should == "Cannot find a compatible package system to check updates for"
    end

    it "should call yum_checkupdates if /usr/bin/yum exists" do
      File.expects(:exist?).with("/usr/bin/yum").returns(true)
      @agent.expects(:yum_checkupdates_action).returns(true)
      result = @agent.call(:checkupdates)
      result.should be_true
      result.should have_data_items(:package_manager=>"yum")
    end

    it "should call apt_checkupdates if /usr/bin/apt-get exists" do
      File.expects(:exist?).with("/usr/bin/yum").returns(false)
      File.expects(:exist?).with("/usr/bin/apt-get").returns(true)
      @agent.expects(:apt_checkupdates_action).returns(true)
      result = @agent.call(:checkupdates)
      result.should have_data_items(:package_manager=>"apt")
      result.should be_true
    end
  end

  describe "#yum_checkupdates" do
    it "should fail if /usr/bin/yum does not exist" do
      File.expects(:exist?).with("/usr/bin/yum").returns(false)
      result = @agent.call(:yum_checkupdates)
      result.should be_aborted_error
      result[:statusmsg].should == "Cannot find yum at /usr/bin/yum"
    end

    it "should succeed if it responds to run and there are no packages to update" do
      File.expects(:exist?).with("/usr/bin/yum").returns(true)
      @agent.expects(:run).with("/usr/bin/yum -q check-update", :stdout => :output, :chomp => true).returns(0)
      result = @agent.call(:yum_checkupdates)
      result.should be_successful
      result.should have_data_items(:exitcode=>0, :outdated_packages=>[])
    end

    it "should succeed if it responds to run and there are packages to update" do
      File.expects(:exist?).with("/usr/bin/yum").returns(true)
      @agent.expects(:run).with("/usr/bin/yum -q check-update", :stdout => :output, :chomp => true).returns(100)
      @agent.expects(:do_yum_outdated_packages)
      result = @agent.call(:yum_checkupdates)
      result.should be_successful
      result.should have_data_items(:outdated_packages=>nil, :exitcode=>100)
    end

    it "should fail if it responds to run but returns a different exit code than 0 or 100" do
      File.expects(:exist?).with("/usr/bin/yum").returns(true)
      @agent.expects(:run).with("/usr/bin/yum -q check-update", :stdout => :output, :chomp => true).returns(2)
      result = @agent.call(:yum_checkupdates)
      result.should be_aborted_error
      result.should have_data_items(:exitcode=>2)
    end
  end

  describe "#apt_checkupdates" do
    it "should fail if /usr/bin/apy-get does not exist" do
      File.expects(:exist?).with("/usr/bin/apt-get").returns(false)
      result = @agent.call(:apt_checkupdates)
      result.should be_aborted_error
      result[:statusmsg].should == "Cannot find apt at /usr/bin/apt-get"
    end

    it "should succeed if it responds to run and returns exit code of 0" do
      @agent.stubs("reply").returns({:output => "Inst emacs23 [23.1+1-4ubuntu7] (23.1+1-4ubuntu7.1 Ubuntu:10.04/lucid-updates) []", :exitcode => 0})

      File.expects(:exist?).with("/usr/bin/apt-get").returns(true)
      @agent.expects(:run).with("/usr/bin/apt-get --simulate dist-upgrade", :stdout => :output, :chomp => true).returns(0)

      result = @agent.call(:apt_checkupdates)
      result.should be_successful

    end

    it "should fail if it responds to 'run' but returns an error code that is not 0" do
      File.expects(:exist?).with("/usr/bin/apt-get").returns(true)
      @agent.expects(:run).with("/usr/bin/apt-get --simulate dist-upgrade", :stdout => :output, :chomp => true).returns(1)
      result = @agent.call(:apt_checkupdates)
      result.should be_aborted_error
      result.should have_data_items(:outdated_packages=>[], :exitcode=>1)
    end
  end

  describe "#do_pkg_action" do
    before(:each) do
      @agent.config.stubs(:pluginconf).returns("package.provider" => "testprovider")
      @provider = mock
      @provider.stubs(:new).returns(@provider)
    end

    it "should load the package provider specified in pluginconf" do
      @provider.expects(:send).with(:status)
      MCollective::PluginManager.expects(:loadclass).with("MCollective::Util::TestproviderPackage")
      MCollective::Util.expects(:const_get).with("TestproviderPackage").returns(@provider)
      result = @agent.call(:status, :package => "puppet")
      result.should be_successful
    end

    it "should fail if specified package provider is not present" do
      result = @agent.call(:status, :package => "puppet")
      result.should be_aborted_error
      result[:statusmsg].should == "Cannot load package provider implementation - testprovider"
    end

    it "should fail if an action hasn't been implemented by the implementation class" do
      class TestPackage < MCollective::Agent::Package::Implementation
      end

      MCollective::PluginManager.expects(:loadclass).with("MCollective::Util::TestproviderPackage")
      MCollective::Util.expects(:const_get).with("TestproviderPackage").returns(TestPackage)
      result = @agent.call(:status, :package => "puppet")
      result.should be_aborted_error
      result[:statusmsg].should == "error. status action has not been implemented"
    end

    it "should call the providers $action method if it has been implemented" do
      class TestPackage < MCollective::Agent::Package::Implementation
        def status
          reply[:output] = "Status call was successful"
        end
      end

      MCollective::PluginManager.expects(:loadclass).with("MCollective::Util::TestproviderPackage")
      MCollective::Util.expects(:const_get).with("TestproviderPackage").returns(TestPackage)
      result = @agent.call(:status, :package => "puppet")
      result.should be_successful
      result.should have_data_items(:output => "Status call was successful")
    end
  end

  describe "#do_yum_outdated_packages" do
    it "should not do anything with obsoleted packages" do
      File.expects(:exist?).with("/usr/bin/yum").returns(true)
      @agent.expects(:run).with("/usr/bin/yum -q check-update", :stdout => :output, :chomp => true).returns(100)
      @agent.stubs(:reply).returns(:output => "Obsoleting")

      result = @agent.call(:yum_checkupdates)
      result.should be_successful
    end

    it "should return packages which need to be updated" do
      File.expects(:exist?).with("/usr/bin/yum").returns(true)
      @agent.expects(:run).with("/usr/bin/yum -q check-update", :stdout => :output, :chomp => true).returns(100)
      @agent.stubs(:reply).returns(:output => "Package version repo", :outdated_packages => "foo")

      result = @agent.call(:yum_checkupdates)
      result.should be_successful
    end
  end
end
