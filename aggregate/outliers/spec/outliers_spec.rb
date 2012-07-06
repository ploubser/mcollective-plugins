#!/usr/bin/env rspec

require 'spec_helper'
require File.dirname(__FILE__) + "/../outliers.rb"

module MCollective
  class Aggregate
    describe Outliers do
      let(:outliers) {Outliers.new(:test, [], nil, :test_action)}

      describe "#startup_hook" do
        it "should set the correct result values" do
          outliers.result[:value].should == {}
          outliers.result[:type].should == :collection
        end

        it "should create an empty data_set array" do
          outliers.data_set.should == []
        end

        it "should create the quartiles hash" do
          outliers.quartiles.should == {:high => nil, :low => nil}
        end
      end

      describe "#process_result" do
        it "should add the result to the data set" do
          outliers.process_result(10, :sender => "mcollective-test")
          outliers.data_set.should == [{:sender => "mcollective-test", :value => 10}]
        end
      end

      describe "#summarize" do
        it "should sort the data set" do
          Array.any_instance.expects(:sort!)
          outliers.stubs(:set_quartiles)
          outliers.stubs(:find_outliers)
          Hash.any_instance.stubs(:empty?).returns(false)
          outliers.summarize
        end

        it "should set the quartiles and find the outliers" do
          Array.any_instance.stubs(:sort!)
          outliers.expects(:set_quartiles)
          outliers.expects(:find_outliers)
          Hash.any_instance.stubs(:empty?).returns(false)
          outliers.summarize
        end

        it "should return an appropriate message if there are no outliers" do
          Array.any_instance.stubs(:sort!)
          outliers.stubs(:set_quartiles)
          outliers.stubs(:find_outliers)
          Hash.any_instance.stubs(:empty?).returns(true)
          outliers.summarize
          outliers.result[:value].should == {"Outliers" => "There are no outliers in this dataset"}
        end
      end

      describe "#set_quartiles" do
        it "should identify the top and bottom quartiles and adjust them by the inter quartile range" do
          [20,22,25,26,30].each do |val|
            outliers.process_result(val, "mcollective-test-#{val}")
          end

          outliers.set_quartiles
          outliers.quartiles[:low].should == 7.75
          outliers.quartiles[:high].should == 41.75
        end
      end

      describe "#find_outliers" do
        it "should find any outliers in a set of data" do
          [20,22,25,26,30,34,23].each do |val|
            outliers.process_result(val, "mcollective-test-#{val}")
          end

          outliers.set_quartiles
          outliers.expects(:create_summary).with([{:value => 34, :sender => nil}], 'High')
          outliers.find_outliers
        end
      end

      describe "#create_summary" do
        it "should create the correct summary of the outlier data" do
          outliers.create_summary([{:value => 12, :sender => "mcollective-test"}], 'Low')
          outliers.result[:value].should == {"Outliers(Low)"=>"mcollective-test = 12"}
        end
      end
    end
  end
end
