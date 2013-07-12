module TradeGraph

  class Item

    attr_reader :id, :title, :unit_price, :seller_id
    attr_accessor :current_stock

    def initialize(args)
      @id = args[:id]
      @title = args[:title]
      @unit_price = args[:unit_price]
      @current_stock = args[:current_stock]
      @seller_id = args[:seller_id]
    end


    # --- Class Finder Methods --- #

    def self.find(id)
      self.items.find { |i| i.id == id }
    end


    # --- Class Methods --- #

    def self.create!(args)
      items << TradeGraph::Item.new(args)
    end

    def self.items
      @@items ||= []
    end

    def self.items=(items)
      @@items = items
    end

    # Alias.
    def self.all
      items
    end

  end
end