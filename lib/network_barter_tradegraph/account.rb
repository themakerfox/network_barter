module TradeGraph

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

end
