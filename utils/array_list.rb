
module Utils
  class ArrayList
    def initialize(values)
      @values = values
    end

    def to_a
      output = []
      iter = @values.iterator

      while (iter.hasNext) do
        element = iter.next
        output << element
      end
      output
    end
  end
end
