module TradeGraph

  class Order

    attr_reader :id, :quantity, :buyer_id, :seller_id, :item_id
    attr_accessor :completed

    @@orders = []

    def initialize(args)
      @id = args[:id]
      @quantity = args[:quantity]
      @buyer_id = args[:buyer_id]
      @seller_id = args[:seller_id]
      @item_id = args[:item_id]
      @completed = args[:completed] || false
    end


    # --- Class Finder Methods --- #

    # Alias.
    def self.all
      orders
    end

    def self.find(id)
      orders.find { |o| o.id == id }
    end

    def self.find_all_by_seller_id(id)
      orders.select { |o| o.seller_id == id }
    end

    def self.find_all_by_buyer_id(id)
      orders.select { |o| o.buyer_id == id }
    end

    def self.all_completed
      orders.select { |o| o.completed? }
    end


    # --- Class Methods --- #

    def self.create!(args)
      args[:id] ||= (orders.map(&:id).max || 0)+1

      orders << TradeGraph::Order.new(args)
    end

    # Executes the given orders - but only if all of them can be executed.
    # Returns TRUE if the orders could be executed - otherwise FALSE.
    def self.execute_orders!(orders)
      orders.each do |o|
        unless o.execute!
          roll_back_orders!(orders)
          return false
        end
      end
      return true
    end

    # rolls back the given orders.
    def self.roll_back_orders!(orders)
      orders.each { |o| o.roll_back! }
    end

    def self.orders
      @@orders
    end

    def self.orders=(orders)
      @@orders = orders
    end


    # --- Instance Methods --- #

    def amount
      quantity * item.unit_price
    end

    def buyer
      @buyer ||= TradeGraph::Account.find(buyer_id)
    end

    def seller
      @seller ||= TradeGraph::Account.find(seller_id)
    end

    def item
      @item ||= TradeGraph::Item.find(item_id)
    end

    # Alias
    def completed?
      completed
    end

    def not_completed?
      !completed
    end

    def execute!
      return false unless can_be_completed?
      item.current_stock = item.current_stock - quantity
      self.completed = true

      #puts show_order
      TradeGraph.increase_counter

      return true
    end

    def roll_back!
      return false unless completed?

      item.current_stock = item.current_stock + quantity
      self.completed = false

      #puts show_order(reverse=true)

      return true
    end

    def can_be_completed?
      #puts TradeGraph.indentation+"Order #{id} completed? #{completed?.to_s}"
      !completed? && item.current_stock >= quantity
    end

    def show_order(reverse=false)
      buyer_str = "(A#{buyer.id} #{buyer.balance}€)".send(buyer.balanced? ? :light_green : :light_red)
      item_str = amount.to_s+'€'
      seller_str = "(A#{seller.id} #{seller.balance}€)".send(seller.balanced? ? :light_green : :light_red)
      #padding_str = '-' * (32 - (buyer_str+item_str+seller_str).length)
      padding_str = '-' * (60 - (buyer_str+item_str+seller_str).length)

      arrow = if reverse
                (padding_str+item_str+'--▶').red
              else
                ('◀--'+item_str+padding_str).green
              end

      #puts TradeGraph.counter

      #if TradeGraph.counter.to_s == 23697.to_s
      #  puts 'BLA BLUB'
      #end


      TradeGraph.indentation+buyer_str+arrow+seller_str+"   Order: #{id}"
    end

  end

end