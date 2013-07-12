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
