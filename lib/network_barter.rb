##
# Main class of the network barter Ruby library.
#
# Provides the full interface to the network barter library, also allowing to select which algorithm implementation
# from the library to use.
#
# Called from:
# rake application:trade:find_and_create -> Trade::create_trade -> NetworkBarter::find_trade_orders
#
# @author matthias
# @todo Add a way (also to the Rake task) how to select the algorithm implementation to use.
# @todo Develop a generic interface between client applications and this gem. See how it's done in TradeGraph. Maybe a
#   way to tell in parameters which tables and columns to use would be good?
class NetworkBarter

  # @todo Rename. A trade consists of orders, it does not exist before them.
  def self.find_trade_orders
    TradeGraph::Account.accounts = Account.all.map do |a|
      TradeGraph::Account.new(id: a.id, acceptable_loss_in_percent: 7)
    end
    TradeGraph::Item.items = Item.active.map do |i|
      TradeGraph::Item.new(id: i.id, title: i.title, unit_price: i.unit_price, current_stock: i.current_stock, seller_id: i.user_id )
    end
    TradeGraph::Order.orders = Order.active.select {|o| o.item.active? }.map do |o|
      TradeGraph::Order.new(
          id: o.id, quantity: o.quantity, seller_id: o.seller_id, buyer_id: o.buyer_id, item_id: o.item_id, completed: o.completed?
      )
    end

    TradeGraph.find_orders_for_trade
  end

end
