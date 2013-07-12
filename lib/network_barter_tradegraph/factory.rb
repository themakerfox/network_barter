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
