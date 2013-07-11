##
# An attempt to implement the network barter algorithm using the Neography graph database.
#
# Only for refernece. This implementation was not completed, the code is not in use.
module DealGraph

  def self.instance
    @@instance ||= Neography::Rest.new
  end

  # Alias.
  def self.graph
    instance
  end


  # Builds the whole graph. Only needed in case the graph needs to be rebuild.
  def self.rebuild
    # Drop all nodes (except node 0) and relationships from the database.
    graph.clean_database('yes_i_really_want_to_clean_the_database')

    # --- Actor Root Node --- #
    c = graph.create_node(name: 'Actors')
    graph.create_relationship('ACTOR_ROOT', graph.get_root, c)
    graph.add_node_to_index(:root_nodes_index, :name, 'Actors', c)

    # --- Item Root Node --- #
    o = graph.create_node(name: 'Items')
    graph.create_relationship('ITEM_ROOT', graph.get_root, o)
    graph.add_node_to_index(:root_nodes_index, :name, 'Items', o)

    # --- OrderRequests --- #
    ::Order.find_each do |order|
      ActorNode.add(order.seller)
      ActorNode.add(order.buyer)
      ItemNode.add(order.item)
      OrderRequestRelationship.add(order)
    end
  end

  # Quick and dirty implementation.
  def self.find_possible_orders(actor)
    node = ActorNode.find(actor)
    graph.get_paths(
        node, node,
        [{type: 'items', direction: 'out'}, {type: 'requested_by', direction: 'out'}],
        depth=10,
        algorithm='allPaths'
    )
  end

  def self.find_possible_orders_new(actor)
    # Example query
    # https://github.com/maxdemarzi/neomatch/blob/master/neomatch.rb
    cypher = "START me=node:users_index(name={user})
      MATCH skills<-[:has]-me-[:lives_in]->city<-[:in_location]-job-[:requires]->requirements
      WHERE me-[:has]->()<-[:requires]-job
      WITH DISTINCT city.name as city_name, job.name AS job_name,
      LENGTH(me-[:has]->()<-[:requires]-job) AS matching_skills,
      LENGTH(job-[:requires]->()) AS job_requires,
      COLLECT(DISTINCT requirements.name) AS req_names, COLLECT(DISTINCT skills.name) AS skill_names
      RETURN city_name, job_name, FILTER(name in req_names WHERE NOT name IN skill_names) AS missing
      ORDER BY matching_skills / job_requires DESC, job_requires
      LIMIT 10"

    graph.execute_query(cypher, {:user => @user})["data"]
  end


  module ActorNode

    def self.graph
      DealGraph.instance
    end

    def self.actor_root_node
      graph.get_node_index(:root_nodes_index, :name, 'Actors')
    end

    def self.find(actor)
      Neography::Node.find(:actors, :id, actor.id) rescue nil
    end

    def self.add(actor)
      return false if find(actor)

      node = graph.create_node(id: actor.id, name: actor.title)
      graph.create_relationship('ACTOR', actor_root_node, node)
      graph.add_node_to_index(:actors, :id, actor.id, node)
    end

    def self.update(actor)
      graph.set_node_properties(find(actor), {name: actor.title})
    end

    def self.remove(actor)
      find(actor).del
    end

  end


  module ItemNode

    def self.graph
      DealGraph.instance
    end

    def self.item_root_node
      graph.get_node_index(:root_nodes_index, :name, 'Items')
    end

    def self.find(item)
      Neography::Node.find(:items, :id, item.id) rescue nil
    end

    def self.add(item)
      return false if find(item)

      item_node = graph.create_node(id: item.id, name: item.title)
      graph.add_node_to_index(:items, :id, item.id, item_node)

      graph.create_relationship(:items, DealGraph::ActorNode.find(item.seller), item_node)

      graph.create_relationship('ITEM', item_root_node, item_node)
    end

    def self.remove(item)
      find(item).del
    end

  end


  module OrderRequestRelationship

    def self.graph
      DealGraph.instance
    end

    def self.add(order)
      item_node = DealGraph::ItemNode.find(order.item)
      buyer_node = DealGraph::ActorNode.find(order.buyer)
      graph.create_relationship(:requested_by, item_node, buyer_node)
    end

  end

end

#
#[{"start" => "http://localhost:7474/db/data/node/64",
#  "nodes" => ["http://localhost:7474/db/data/node/64"],
#  "length" => 0, "relationships" => [], "end" => "http://localhost:7474/db/data/node/64"
# },
#
# {"start" => "http://localhost:7474/db/data/node/64",
#  "nodes" => ["http://localhost:7474/db/data/node/64",
#              "http://localhost:7474/db/data/node/69",
#              "http://localhost:7474/db/data/node/66",
#              "http://localhost:7474/db/data/node/70",
#              "http://localhost:7474/db/data/node/64"],
#  "length" => 4,
#  "relationships" => ["http://localhost:7474/db/data/relationship/67",
#                      "http://localhost:7474/db/data/relationship/74",
#                      "http://localhost:7474/db/data/relationship/69",
#                      "http://localhost:7474/db/data/relationship/75"],
#  "end" => "http://localhost:7474/db/data/node/64"},
#
# {"start" => "http://localhost:7474/db/data/node/64",
#  "nodes" => ["http://localhost:7474/db/data/node/64",
#              "http://localhost:7474/db/data/node/68",
#              "http://localhost:7474/db/data/node/65",
#              "http://localhost:7474/db/data/node/71",
#              "http://localhost:7474/db/data/node/66",
#              "http://localhost:7474/db/data/node/70",
#              "http://localhost:7474/db/data/node/64"],
#  "length" => 6,
#  "relationships" => ["http://localhost:7474/db/data/relationship/65",
#                      "http://localhost:7474/db/data/relationship/73",
#                      "http://localhost:7474/db/data/relationship/71",
#                      "http://localhost:7474/db/data/relationship/76",
#                      "http://localhost:7474/db/data/relationship/69",
#                      "http://localhost:7474/db/data/relationship/75"],
#  "end" => "http://localhost:7474/db/data/node/64"}
#]
