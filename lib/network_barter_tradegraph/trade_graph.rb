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
end