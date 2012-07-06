module MCollective
  class Aggregate
    class Outliers<Base

      attr_reader :data_set, :quartiles

      def startup_hook
        result[:value] = {}
        result[:type] = :collection
        @aggregate_format = "%s : %s" unless @aggregate_format

        @data_set = []
        @quartiles = {:high => nil,
                      :low=> nil}
        @arguments[0] = 2 unless @arguments[0]
      end

      def process_result(value, reply)
        @data_set << {:sender => reply[:sender], :value => value}
      end

      def summarize
        @data_set.sort!{|a,b| a[:value] <=> b[:value]}
        set_quartiles
        find_outliers
        if result[:value].empty?
          result[:value]["Outliers"] = "There are no outliers in this dataset"
        end
        super
      end

      def set_quartiles
        n = @data_set.size + 1
        l = Float((1.0/4.0)*(n))
        u = Float((3.0/4.0)*(n))

        q1 = ((0.75 * (@data_set[l.truncate - 1][:value])) + (0.25 * @data_set[l.truncate][:value]))
        q3 = ((0.25 * (@data_set[u.truncate - 1][:value])) + (0.75 * @data_set[u.truncate][:value]))

        iqr = (q3 - q1).abs

        @quartiles[:low] = q1 - (1.5 * iqr)
        @quartiles[:high] = q3 + (1.5 * iqr)
      end

      def find_outliers
        high = []
        low = []

        @data_set.each do |data_item|
          high << data_item if data_item[:value] > @quartiles[:high]
          low << data_item if data_item[:value] < @quartiles[:low]
        end

        create_summary(high, 'High') unless high.empty?
        create_summary(low, 'Low') unless low.empty?
      end

      def create_summary(position, name)
        position.sort!{|a,b| b[:value] <=> a[:value]}
        position = position.slice(0, @arguments.first) unless position.size <= @arguments.first
        result[:value]["Outliers(#{name})"] = position.map{|resp| "#{resp[:sender]} = #{resp[:value]}"}.join(", ") unless position.empty?
      end
    end
  end
end
