#!/usr/bin/env rspec
require 'spec_helper'
require File.join(File.dirname(__FILE__), "../agent/package.rb")
require File.join(File.dirname(__FILE__), "../util/puppetpackage.rb")

module MCollective
  module Util
    describe PuppetPackage do

      describe "Package Provider" do
        it "should create an instance of the puppet package provider" do
          provider = MCollective::Util::PuppetPackage.new("package", {})
          provider.pkg_provider.class.to_s.should match(/Puppet::Type::Package::Provider/)
        end

        it "should only create one instance of the puppet package provider" do
          provider = MCollective::Util::PuppetPackage.new("package", {})
          id = provider.pkg_provider.object_id
          id.should == provider.pkg_provider.object_id
        end
      end

      describe "Package Actions" do
        before do
          @provider = mock
          @provider.stubs(:flush)
          @package = MCollective::Util::PuppetPackage.new("package", {:output => nil, :properties => nil})
          @package.stubs(:pkg_provider).returns(@provider)
        end

        it "should install a package if ensure is absent" do
          @provider.stubs(:properties).returns({:ensure => :absent})
          @provider.expects(:install).returns("installed")
          @package.install
          @package.reply[:output].should == "installed"
        end

        it "should not install a package if ensure is not absent" do
          @provider.stubs(:properties).returns({:ensure => :present})
          @provider.expects(:install).never
          @package.install
          @package.reply[:output].should == nil
        end

        it "should update a package unless ensure is absent" do
          @provider.stubs(:properties).returns({:ensure => :present})
          @provider.expects(:update).returns("updated")
          @package.update
          @package.reply[:output].should == "updated"
        end

        it "should not update a package if ensure is absent" do
          @provider.stubs(:properties).returns({:ensure => :absent})
          @provider.expects(:update).never
          @package.update
          @package.reply[:output].should == nil
        end

        it "should uninstall a package unless ensure is absent" do
          @provider.stubs(:properties).returns({:ensure => :present})
          @provider.expects(:uninstall).returns("uninstalled")
          @package.uninstall
          @package.reply[:output].should == "uninstalled"
        end

        it "should not uninstall a package if ensure is absent" do
          @provider.stubs(:properties).returns({:ensure => :absent})
          @provider.expects(:uninstall).never
          @package.uninstall
          @package.reply[:output].should == nil
        end

        it "should return a package's status" do
          @provider.stubs(:properties).returns("Package status")
          @package.status
          @package.reply[:properties].should == "Package status"
        end

        it "should purge a package" do
          @provider.stubs(:purge).returns("Purged")
          @package.purge
          @package.reply[:output].should == "Purged"
        end
      end
    end
  end
end
