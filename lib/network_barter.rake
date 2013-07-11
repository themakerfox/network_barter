# encoding: utf-8

namespace :network_barter do

    ##
    # Rake task to let the network barter algorithm find a network barter deal during development.
    #
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

end
