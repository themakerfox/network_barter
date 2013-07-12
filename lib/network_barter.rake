# encoding: utf-8

namespace :network_barter_xtremebarter do

end

namespace :network_barter_tradegraph do

  ## Find a network barter deal during development.
  # Start as: rake application:trade:find_trade
  # @todo Introduce a rake parameter for selecting the testing set, or even test configuration paramaters.
  task find_trade: :environment do
    puts
    puts
    puts Time.now
    puts 'Start...'
    orders = NetworkBarter.find_trade_orders
    puts 'Seller IDs: '+orders.map {|o| o.seller.id }.sort.join(', ')
    puts 'Buyer IDs: '+orders.map {|o| o.buyer.id }.sort.join(', ')
    orders.each do |order|
      puts "ORDER: #{order.id}"
      puts order.seller.print_state
    end
    puts
    puts Time.now
  end

  task test_1: :environment do
    TradeGraph::Test.medium_sized_graph_with_beneficiary_account
  end

  task test_all: :environment do
    TradeGraph::Test.all
  end

end
