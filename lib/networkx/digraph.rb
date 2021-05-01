module NetworkX
  # Describes the class for making Directed Graphs
  #
  # @attr_reader adj [Hash{ Object => Hash{ Object => Hash{ Object => Object } } }]
  #                  Stores the edges and their attributes in an adjencency list form
  # @attr_reader pred [Hash{ Object => Hash{ Object => Hash{ Object => Object } } }]
  #                  Stores the reverse edges and their attributes in an adjencency list form
  # @attr_reader nodes [Hash{ Object => Hash{ Object => Object } }] Stores the nodes and their attributes
  # @attr_reader graph [Hash{ Object => Object }] Stores the attributes of the graph
  class DiGraph < Graph
    attr_reader :adj, :nodes, :graph, :pred

    # Constructor for initializing graph
    #
    # @example Initialize a graph with attributes 'type' and 'name'
    #   graph = NetworkX::Graph.new(name: "Social Network", type: "undirected")
    #
    # @param graph_attrs [Hash{ Object => Object }] the graph attributes in a hash format
    def initialize(**graph_attrs)
      super(**graph_attrs)

      @pred = {}
    end

    # Adds the respective edge
    #
    # @example Add an edge with attribute name
    #   graph.add_edge(node1, node2, name: "Edge1")
    #
    # @example Add an edge with no attribute
    #   graph.add_edge("Bangalore", "Chennai")
    #
    # @param node_1 [Object] the first node of the edge
    # @param node_2 [Object] the second node of the edge
    # @param edge_attrs [Hash{ Object => Object }] the hash of the edge attributes
    def add_edge(node_1, node_2, **edge_attrs)
      add_node(node_1)
      add_node(node_2)

      edge_attrs = (@adj[node_1][node_2] || {}).merge(edge_attrs)
      @adj[node_1][node_2] = edge_attrs
      @pred[node_2][node_1] = edge_attrs
    end

    # Adds a node and its attributes to the graph
    #
    # @example Add a node with attribute 'type'
    #   graph.add_node("Noida", type: "city")
    #
    # @param node [Object] the node object
    # @param node_attrs [Hash{ Object => Object }] the hash of the attributes of the node
    def add_node(node, **node_attrs)
      super(node, **node_attrs)

      @pred[node] = {} unless @pred.key?(node)
    end

    # Removes node from the graph
    #
    # @example
    #   graph.remove_node("Noida")
    #
    # @param node [Object] the node to be removed
    def remove_node(node)
      raise KeyError, "Error in deleting node #{node} from Graph." unless @nodes.key?(node)

      neighbours = @adj[node]
      neighbours.each_key { |k| @pred[k].delete(node) }
      @pred[node].each_key do |k|
        @adj[k].delete(node)
      end

      @pred.delete(node)
      @adj.delete(node)
      @nodes.delete(node)
    end

    # Removes edge from the graph
    #
    # @example
    #   graph.remove_edge('Noida', 'Bangalore')
    #
    # @param node_1 [Object] the first node of the edge
    # @param node_2 [Object] the second node of the edge
    def remove_edge(node_1, node_2)
      raise KeyError, "#{node_1} is not a valid node." unless @nodes.key?(node_1)
      raise KeyError, "#{node_2} is not a valid node" unless @nodes.key?(node_2)
      raise KeyError, 'The given edge is not a valid one.' unless @adj[node_1].key?(node_2)

      @adj[node_1].delete(node_2)
      @pred[node_2].delete(node_1)
    end

    # Clears the graph
    #
    # @example
    #   graph.clear
    def clear
      super

      @pred.clear
    end

    # Returns number of edges
    #
    # @example
    #   graph.number_of_edges
    def number_of_edges
      @adj.values.map(&:length).inject(:+)
    end

    # Returns the size of graph
    #
    # @example
    #   graph.size(true)
    #
    # @param is_weighted [Bool] if true, method returns sum of weights of all edges
    #                            else returns number of edges
    def size(is_weighted=false)
      if is_weighted
        graph_size = 0
        @adj.each do |_, hash_val|
          hash_val.each { |_, v| graph_size += v[:weight] if v.key?(:weight) }
        end
        return graph_size
      end
      number_of_edges
    end

    # Returns in-degree of a given node
    #
    # @example
    #   graph.in_degree(node)
    #
    # @param node [Object] the node whose in degree is to be calculated
    def in_degree(node)
      @pred[node].length
    end

    # Returns out-degree of a given node
    #
    # @example
    #   graph.out_degree(node)
    #
    # @param node [Object] the node whose out degree is to be calculated
    def out_degree(node)
      @adj[node].length
    end

    # Returns the reversed version of the graph
    #
    # @example
    #   graph.reverse
    def reverse
      new_graph = NetworkX::DiGraph.new(**@graph)
      @nodes.each { |u, attrs| new_graph.add_node(u, **attrs) }
      @adj.each do |u, edges|
        edges.each { |v, attrs| new_graph.add_edge(v, u, **attrs) }
      end
      new_graph
    end

    # Returns the undirected version of the graph
    #
    # @example
    #   graph.to_undirected
    def to_undirected
      new_graph = NetworkX::Graph.new(**@graph)
      @nodes.each { |u, attrs| new_graph.add_node(u, **attrs) }
      @adj.each do |u, edges|
        edges.each { |v, attrs| new_graph.add_edge(u, v, **attrs) }
      end
      new_graph
    end

    # TODO: Reduce method complexity and method length

    # Returns subgraph consisting of given array of nodes
    #
    # @example
    #   graph.subgraph(%w[Mumbai Nagpur])
    #
    # @param nodes [Array<Object>] the nodes to be included in the subgraph
    def subgraph(nodes)
      case nodes
      when Array, Set
        sub_graph = NetworkX::DiGraph.new(**@graph)
        nodes.each do |u|
          raise KeyError, "#{u} does not exist in the current graph!" unless node?(u)

          sub_graph.add_node(u, **@nodes[u])
          @adj[u].each do |v, uv_attrs|
            sub_graph.add_edge(u, v, **uv_attrs) if @adj[u].key?(v) && nodes.include?(v)
          end
          return sub_graph
        end
      else
        raise ArgumentError, 'Expected Argument to be Array or Set of nodes, '\
                            "received #{nodes.class.name} instead."
      end
    end

    # TODO: Reduce method complexity and method length

    # Returns subgraph consisting of given edges
    #
    # @example
    #   graph.edge_subgraph([%w[Nagpur Wardha], %w[Nagpur Mumbai]])
    #
    # @param edges [Array<Object, Object>] the edges to be included in the subraph
    def edge_subgraph(edges)
      case edges
      when Array, Set
        sub_graph = NetworkX::DiGraph.new(**@graph)
        edges.each do |u, v|
          raise KeyError, "Edge between #{u} and #{v} does not exist in the graph!" unless @nodes.key?(u)\
                                                                                    && @adj[u].key?(v)

          sub_graph.add_node(u, **@nodes[u])
          sub_graph.add_node(v, **@nodes[v])
          sub_graph.add_edge(u, v, **@adj[u][v])
        end
        return sub_graph
      else
        raise ArgumentError, 'Expected Argument to be Array or Set of edges, '\
        "received #{edges.class.name} instead."
      end
    end
  end
end
