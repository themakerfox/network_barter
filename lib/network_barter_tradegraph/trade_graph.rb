# encoding: UTF-8

##
# First working (but prototypical) implementation of the network barter algorithm.
#
# Ideas to improve the search performance:
# * Find out if it is possible to predict what amount a beneficiary account is most likely to receive from a network.
#   If this is possible, start with the items on the beneficiary accounts wishlist whose value is closes to the
#   amount determined amount. The calculation might factor in the amounts average price in the network, the average
#   acceptable loss in percent...
module TradeGraph

  require 'pp'
  require 'colorize'

  @@current_depth = 0
  @@counter = 0

  # @return The orders in an Array.
  def self.find_orders_for_trade
    TradeGraph::Account.all_beneficiary.each do |account|

      if account.balance_account!
        puts TradeGraph.counter
        return TradeGraph::Order.all_completed
      end
    end

    puts "Executed orders: #{TradeGraph.counter}"

    return []
  end

  def self.find_orders_for_trade_without_beneficiary_account
    TradeGraph::Account.all.each do |account|
      if account.balance_account!
        puts TradeGraph.counter
        return TradeGraph::Order.all_completed
      end
    end

    puts "Executed orders: #{TradeGraph.counter}"

    return []
  end

  #
  #def find_valid_order_set
  #  orders = 'all orders except the orders made by beneficiary accounts'
  #  3.upto(5) do |set_size|
  #    orders.combination(set_size).each do | |
  #      TradeGraph::Account.all_beneficiary.each do |account|
  #        # @todo try if downto works better (finds stuff faster...)
  #        1.upto(5) do |i|
  #          account.orders.combination(i).to_a.each do |set|
  #          end
  #        end
  #      end
  #    end
  #  end
  #end


  def self.current_depth
    @@current_depth
  end

  def self.increase_depth
    @@current_depth += 1
  end

  def self.decrease_depth
    @@current_depth -= 1
  end


  def self.counter
    @@counter
  end

  def self.increase_counter
    @@counter += 1
  end

  def self.decrease_counter
    @@counter -= 1
  end

  # TradeGraph.indentation
  def self.indentation
    '                        '*@@current_depth
  end

  def self.show_graph
    puts '### ACCOUNTS ###'
    TradeGraph::Account.all.each do |a|
      puts "A#{a.id}: max. loss #{a.acceptable_loss_in_percent}% - beneficiary #{a.beneficiary}"
    end
    puts
    puts '### PRODUCTS ###'
    TradeGraph::Product.all.each do |i|
      puts "I#{i.id}: #{i.title} - unit-price: #{i.unit_price} - current-stock: #{i.current_stock} - seller-id: #{i.seller_id}"
    end
    puts
    puts '### ORDERS ###'
    TradeGraph::Order.all.each do |o|
      puts "O#{o.id}: seller-id: #{o.seller_id} - item-id: #{o.item_id} - buyer-id: #{o.buyer_id} - quantity: #{o.quantity} - completed: #{o.completed}"
    end
  end


  class Account

    attr_reader :id, :acceptable_loss_in_percent, :beneficiary, :order_set_combinations

    def initialize(args)
      @id = args[:id]
      @acceptable_loss_in_percent = args[:acceptable_loss_in_percent]
      @beneficiary = args[:beneficiary] || false

    end


    # --- Class Finder Methods --- #

    def self.find(id)
      accounts.find { |a| a.id == id }
    end

    def self.all_beneficiary
      accounts.select { |a| a.beneficiary }
    end


    # --- Class Methods --- #

    def self.create!(args)
      accounts << TradeGraph::Account.new(args)
    end

    def self.accounts
      @@users ||= []
    end

    def self.accounts=(accounts)
      @@users = accounts
    end

    # Alias.
    def self.all
      accounts
    end


    # --- Instance Methods --- #

    # This method must be callced after all items, orders and accounts are loaded in the graph so that the graph structure
    # will not change.
    # @todo To do this it might be a good idea to load all the graph-data when the graph is initialized e.g.
    # TradeGraph.new(items: [...], orders: [...], accounts: [...]) So this can be done in the TradGraph initialize method.
    def generate_order_set_combinations
      sums_of_received_orders = [10, 15, 10, 40]
      sums_of_made_orders = [16, 25, 30, 20]

      #
    end


    # @todo do not return order sets that lead in the wrong direction. These are all order-sets that are associated
    # with sellers that are not well connected
    def possible_order_sets_that_will_balance_the_account
      order_sets = []

      generate_order_sets(open_created_orders).each do |order_set|
        order_sets << order_set if orders_will_balance_account?(order_set)
      end

      # IMPORTANT! The order of the order_sets is the most important part of the algorithm as it
      # determines the direction of the search path.
      # Ranking Factors that contribute to a higher ranking:
      # * The order set's orders refer to sellers that have closed orders (means they are part of the current balanced network).
      #   (right now this is done by the generate_order_sets method)
      # * The more valid order-sets a seller has. Because it is easier to balance an account with many order-sets than
      #   one with just a few.
      # * The less orders the order-set has. Because many orders means that many accounts are involved which means
      #   that many accounts will be unbalanced when the orders are executed and need to be balanced again.
      # * The higher the loss is. Makes sense when the starting account is a beneficiary account. Higher loss per
      #   order means less accounts need to be involved in a trade to `soak up` the value that the beneficiary account
      #   will receive.
      # * The greater the cohesion (the more connections) of the seller is to the current balanced network.

      # Sort the swaps ascending by their balance amount. Because it is easier to make a swap with a small balance
      # than one with a large balance.
      # This is because the 'balance' is aggregated loss that friends make. It is more likely to find a swap where
      # one gives 100 EUR and gets 105 EUR (balance 5) than it is to give 10 EUR and get 510 EUR (balance 500).
      # order.sort_by! { |s| s.balance }

      order_sets
    end


    # @todo improve!
    def generate_order_sets(orders)
      order_sets = []
      max_number_of_order_sets = 2000

      # NOTE: We use upto to have the smallest sets first in the array as it is more likely to make a swap with
      # a small set than with a large set.
      1.upto(orders.length) do |i|
        combinations = orders.combination(i).to_a
        break if order_sets.length + combinations.length > max_number_of_order_sets
        order_sets.concat(combinations)
      end

      # Move all orders to the front whose seller is part of the current balanced network.
      # In this way these orders are processed first which will keep the network as small as possible.
      seller_ids = TradeGraph::Order.all_completed.map { |o| o.seller_id }

      order_sets.each do |set|
        set_seller_ids = set.map { |o| o.seller_id }
        order_sets.unshift(order_sets.delete(set)) unless (seller_ids & set_seller_ids).empty?
      end

      order_sets
    end


    # @return the orders that where completed to balance the account or FALSE if the account could not be balanced.
    def balance_account!
      possible_order_sets_that_will_balance_the_account.each do |order_set|
        order_ids = order_set.map { |o| o.id }.join(',')
        #puts "A#{id}: START ORDER SET: #{order_ids}..."
        completed_orders = []

        if Order.execute_orders!(order_set)
          all_balanced = true
          completed_orders += order_set

          order_set.each do |order|
            # NOTE: Do not use order_set.select {|o| o.seller.unbalanced? } as sellers can be balanced on a sub-level.
            # Therefore this must be checked in the loop!
            next if order.seller.balanced?

            TradeGraph.increase_depth
            balance_seller_result = order.seller.balance_account!
            TradeGraph.decrease_depth
            if balance_seller_result
              completed_orders += balance_seller_result
            else
              Order.roll_back_orders!(completed_orders)
              all_balanced = false
              break
            end
          end

          return completed_orders if all_balanced
        end
        #puts
      end

      return false
    end


    # NOTE: only created-orders are allowed
    def orders_will_balance_account?(orders)
      orders_total = orders.inject(0) { |sum, order| sum + order.amount }
      acceptable_loss = orders_total.to_f * (acceptable_loss_in_percent.to_f/100.0)

      balance + orders_total + acceptable_loss >= 0
    end

    def beneficiary?
      beneficiary
    end


    # --- Order Methods --- #

    def received_orders
      @received_orders ||= TradeGraph::Order.find_all_by_seller_id(id)
    end

    def created_orders
      @created_orders ||= TradeGraph::Order.find_all_by_buyer_id(id)
    end

    def completed_received_orders
      received_orders.select { |o| o.completed? }
    end

    def completed_created_orders
      created_orders.select { |o| o.completed? }
    end

    def open_received_orders
      received_orders.select { |o| !o.completed? }
    end

    def open_created_orders
      created_orders.select { |o| !o.completed? }
    end


    # --- Balance Methods --- #

    def balance
      received_value - given_value
    end

    # TRUE when more is received than given away.
    def positive_balance?
      balance >= 0
    end

    # TRUE when more is given than received.
    def negative_balance?
      balance < 0
    end

    def acceptable_loss
      (received_value == 0) ? 0 : (received_value.to_f / 100) * acceptable_loss_in_percent
    end

    def received_value
      completed_created_orders.inject(0) { |sum, order| sum + order.amount }
    end

    def given_value
      completed_received_orders.inject(0) { |sum, order| sum + order.amount }
    end

    def balanced?
      balance + acceptable_loss >= 0
    end

    def unbalanced?
      !balanced?
    end

    def print_state
      puts "### ACCOUNT #{id} ###"
      puts "Balance: #{balance}"
      puts "Balanced? #{balanced?}"
      puts "--- Received Items ---"
      created_orders.each do |o|
        next unless o.completed?
        puts "#{o.quantity}x #{o.item.title} (#{o.amount}EUR)"
      end
      puts "--- Given Items ---"
      received_orders.each do |o|
        next unless o.completed?
        puts "#{o.quantity}x #{o.item.title} (#{o.amount}EUR)"
      end
      puts
    end

  end


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


  module Factory

    # items_unit_price: 10..100
    # items_current_stock: 1..5
    # acceptable_loss_in_percent: 1..10
    #
    # number_of_accounts: 100
    # number_of_orders: 200
    # number_of_items: 200
    def self.build(args={})
      user_ids = (1..args[:number_of_accounts]).to_a
      item_ids = (1..args[:number_of_items]).to_a
      order_ids = (1..args[:number_of_orders]).to_a

      user_ids.each do |id|
        TradeGraph::Account.create!(id: id, acceptable_loss_in_percent: rand(args[:acceptable_loss_in_percent]))
      end

      item_ids.each do |id|
        TradeGraph::Item.create!(
            id: id, title: "Item #{id}", unit_price: rand(args[:items_unit_price]),
            seller_id: user_ids.sample, current_stock: rand(args[:items_current_stock])
        )
      end

      order_ids.each do |id|
        # We make sure seller and buyer are not the same.
        seller_id, buyer_id = user_ids.sample(2)
        TradeGraph::Order.create!(id: id, quantity: 1, seller_id: seller_id, item_id: item_ids.sample, buyer_id: buyer_id)
      end
    end

  end


  module Test


    def self.build_small_sized_graph!
      TradeGraph::Factory.build(
          number_of_accounts: 10, number_of_items: 50, number_of_orders: 50,
          items_unit_price: 2..10, items_current_stock: 1..1, acceptable_loss_in_percent: 4..10,
      )
    end


    def self.build_medium_sized_graph!
      TradeGraph::Factory.build(
          number_of_accounts: 100, number_of_items: 200, number_of_orders: 200,
          items_unit_price: 5..200, items_current_stock: 1..5, acceptable_loss_in_percent: 4..10,
      )
    end


    # TradeGraph::Test.medium_sized_graph_with_beneficiary_account
    def self.medium_sized_graph_with_beneficiary_account
      build_small_sized_graph!
      # Add a beneficiary account
      TradeGraph::Account.create!(id: 0, acceptable_loss_in_percent: 0, beneficiary: true)
      # Put all items on the beneficiary accounts wishlist.
      TradeGraph::Item.all.each do |item|
        TradeGraph::Order.create!(quantity: 1, seller_id: item.seller_id, item_id: item.id, buyer_id: 0)
      end

      # TradeGraph.show_graph

      orders = TradeGraph.find_orders_for_trade

      puts '#####################'
      puts "Order Ids: #{orders.map(&:id)}"

      orders.each do |order|
        puts "ORDER: #{order.id}"
        puts order.buyer.print_state
      end
    end


    def self.medium_sized_graph_without_beneficiary_account
      build_small_sized_graph!
      orders = TradeGraph.find_orders_for_trade_without_beneficiary_account

      puts '#####################'
      puts "Order Ids: #{orders.map(&:id)}"

      orders.each do |order|
        puts "ORDER: #{order.id}"
        puts order.buyer.print_state
      end
    end


    def self.all
      #r1 = t1
      r2 = t2
      puts
      puts
      puts '### TEST RESULTS ###'
      #puts "t1: #{r1}"
      puts "t2: #{r2}"

      r2.each do |order|
        puts "ORDER: #{order.id}"
        puts order.buyer.print_state
      end

    end


    def self.t1
      TradeGraph::Account.accounts = [
          TradeGraph::Account.new(id: 1, acceptable_loss_in_percent: 0, beneficiary: true),
          TradeGraph::Account.new(id: 2, acceptable_loss_in_percent: 7, beneficiary: false),
          TradeGraph::Account.new(id: 3, acceptable_loss_in_percent: 10, beneficiary: false),
          TradeGraph::Account.new(id: 4, acceptable_loss_in_percent: 50, beneficiary: false),
      ]
      TradeGraph::Item.items = [
          TradeGraph::Item.new(id: 1, title: 'Item 1', unit_price: 70, current_stock: 10, seller_id: 1),
          TradeGraph::Item.new(id: 2, title: 'Item 2', unit_price: 100, current_stock: 10, seller_id: 2),
          TradeGraph::Item.new(id: 3, title: 'Item 3', unit_price: 100, current_stock: 10, seller_id: 3),
          TradeGraph::Item.new(id: 4, title: 'Item 4', unit_price: 100, current_stock: 10, seller_id: 4),
      ]
      TradeGraph::Order.orders = [
          TradeGraph::Order.new(id: 1, quantity: 1, seller_id: 1, item_id: 1, buyer_id: 4, completed: false),
          TradeGraph::Order.new(id: 2, quantity: 1, seller_id: 2, item_id: 2, buyer_id: 3, completed: false),
          TradeGraph::Order.new(id: 3, quantity: 1, seller_id: 3, item_id: 3, buyer_id: 1, completed: false),
          TradeGraph::Order.new(id: 4, quantity: 1, seller_id: 4, item_id: 4, buyer_id: 2, completed: false),
      ]

      TradeGraph.find_orders_for_trade.map { |o| o.id } # == [2, 3, 4]
    end


    def self.t2
      TradeGraph::Account.accounts = [
          TradeGraph::Account.new(id: 1, acceptable_loss_in_percent: 0, beneficiary: true),
          TradeGraph::Account.new(id: 2, acceptable_loss_in_percent: 80, beneficiary: false),
          TradeGraph::Account.new(id: 3, acceptable_loss_in_percent: 80, beneficiary: false),
          TradeGraph::Account.new(id: 4, acceptable_loss_in_percent: 80, beneficiary: false),
      ]
      TradeGraph::Item.items = [
          TradeGraph::Item.new(id: 1, title: 'Item 1', unit_price: 10, current_stock: 10, seller_id: 2),
          TradeGraph::Item.new(id: 2, title: 'Item 2', unit_price: 15, current_stock: 10, seller_id: 2),
          TradeGraph::Item.new(id: 3, title: 'Item 3', unit_price: 10, current_stock: 10, seller_id: 3),
          TradeGraph::Item.new(id: 4, title: 'Item 4', unit_price: 10, current_stock: 10, seller_id: 3),
          TradeGraph::Item.new(id: 5, title: 'Item 5', unit_price: 20, current_stock: 10, seller_id: 4),
          TradeGraph::Item.new(id: 6, title: 'Item 6', unit_price: 5, current_stock: 10, seller_id: 4),
      ]
      TradeGraph::Order.orders = [
          TradeGraph::Order.new(id: 1, quantity: 1, seller_id: 2, item_id: 1, buyer_id: 1, completed: false),
          TradeGraph::Order.new(id: 2, quantity: 1, seller_id: 2, item_id: 2, buyer_id: 4, completed: false),
          TradeGraph::Order.new(id: 3, quantity: 1, seller_id: 3, item_id: 3, buyer_id: 2, completed: false),
          TradeGraph::Order.new(id: 4, quantity: 1, seller_id: 3, item_id: 4, buyer_id: 4, completed: false),
          TradeGraph::Order.new(id: 5, quantity: 1, seller_id: 4, item_id: 5, buyer_id: 3, completed: false),
          TradeGraph::Order.new(id: 6, quantity: 1, seller_id: 4, item_id: 6, buyer_id: 2, completed: false),
      ]

      TradeGraph.find_orders_for_trade #.map { |o| o.id } # == [1, 2, 3, 4, 5, 6]
    end

  end

end


#TradeGraph::Test.medium_sized_graph_with_beneficiary_account

#TradeGraph::Test.all
