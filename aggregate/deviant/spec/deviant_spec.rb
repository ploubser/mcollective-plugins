#!/usr/bin/env rspec

require 'spec_helper'
require File.dirname(__FILE__) + "/../../../../../plugins/mcollective/aggregate/deviant.rb"

module MCollective
  class Aggregate
    describe Deviant do
      let(:deviant) {Deviant.new(:test, [], nil, :test_action)}

      describe "#startup_hook" do

        it "should set the correct values to the result hash" do
          deviant.result[:value].should == {}
          deviant.result[:type].should == :collection
        end

        it "should set a default aggregate_format" do
          deviant.aggregate_format.should == "%s : %s"
        end

        it "should create an empty data_set array" do
          deviant.data_set.should == []
        end
      end

      describe "#process_result" do
        it "should add a sender and a value to the data_set array" do
          deviant.process_result(10, {:sender => "mcollective-test"})
          deviant.data_set.should == [["mcollective-test", 10]]
        end
      end

      describe "#summarize" do
        it "should limit the deviants to 2 if no second arguments were passed" do
          [1,2,3,4,5].each do |val|
            deviant.process_result("mcollective-test-{val}", val)
          end

          deviant.summarize
          deviant.result[:value]["Deviants(High)"].size.should == 1
          deviant.result[:value]["Deviants(Low)"].size.should == 1
        end

        it "should calculate the correct deviants" do
          [1,2,3,4,5].each do |val|
            deviant.process_result("mcollective-test-{val}", val)
          end

          deviant.summarize
          deviant.result[:value].should == {"Deviants(Low)"=>[[0, "mcollective-test-{val}"]], "Deviants(High)"=>[[0, "mcollective-test-{val}"]]}
        end

        it "should correctly place more deviants in the 'High' list if an uneven amount of deviants are being calculated" do
          new_deviant = Deviant.new(:test, [3], nil, :test_action)
          [1,2,3,4,5].each do |val|
            new_deviant.process_result("mcollective-test-{val}", val)
          end

          new_deviant.summarize
          new_deviant.result[:value]["Deviants(High)"].size.should == 2
          new_deviant.result[:value]["Deviants(Low)"].size.should == 1
        end

        it "should calculate the correct amount of deviants if a second argument was passed" do
          new_deviant = Deviant.new(:test, [4], nil, :test_action)
          [1,2,3,4,5].each do |val|
            new_deviant.process_result("mcollective-test-{val}", val)
          end

          new_deviant.summarize
          new_deviant.result[:value]["Deviants(High)"].size.should == 2
          new_deviant.result[:value]["Deviants(Low)"].size.should == 2
        end
      end
    end
  end
end
