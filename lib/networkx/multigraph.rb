module NetworkX
  # Describes the class for making MultiGraphs
  #
  # @attr_reader adj [Hash{ Object => Hash{ Object => Hash{ Integer => Hash{ Object => Object } } } }]
  #                  Stores the edges and their attributes in an adjencency list form
  # @attr_reader nodes [Hash{ Object => Hash{ Object => Object } }] Stores the nodes and their attributes
  # @attr_reader graph [Hash{ Object => Object }] Stores the attributes of the gra
  class MultiGraph < Graph
    # Returns a new key
    #
    # @param node_1 [Object] the first node of a given edge
    # @param node_2 [Object] the second node of a given edge
    def new_edge_key(node_1, node_2)
      return 0 if @adj[node_1][node_2].nil?

      key = @adj[node_1][node_2].length
      key += 1 while @adj[node_1][node_2].key?(key)
      key
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
      key = new_edge_key(node_1, node_2)
      all_edge_attrs = @adj[node_1][node_2] || {}
      all_edge_attrs[key] = edge_attrs
      @adj[node_1][node_2] = all_edge_attrs
      @adj[node_2][node_1] = all_edge_attrs
    end

    # TODO: Reduce method complexity

    # Removes edge from the graph
    #
    # @example
    #   graph.remove_edge('Noida', 'Bangalore')
    #
    # @param node_1 [Object] the first node of the edge
    # @param node_2 [Object] the second node of the edge
    def remove_edge(node_1, node_2, key=nil)
      if key.nil?
        super(node_1, node_2)
        return
      end
      raise KeyError, "#{node_1} is not a valid node." unless @nodes.key?(node_1)
      raise KeyError, "#{node_2} is not a valid node" unless @nodes.key?(node_2)
      raise KeyError, 'The given edge is not a valid one.' unless @adj[node_1].key?(node_2)
      raise KeyError, 'The given edge is not a valid one.' unless @adj[node_1][node_2].key?(key)

      @adj[node_1][node_2].delete(key)
      @adj[node_2][node_1].delete(key)
    end

    # Returns the size of the graph
    #
    # @example
    #   graph.size(true)
    #
    # @param is_weighted [Bool] if true, method returns sum of weights of all edges
    #                           else returns number of edges
    def size(is_weighted=false)
      if is_weighted
        graph_size = 0
        @adj.each do |_, hash_val|
          hash_val.each { |_, v| v.each { |_, attrs| graph_size += attrs[:weight] if attrs.key?(:weight) } }
        end
        return graph_size / 2
      end
      number_of_edges
    end

    # Returns number of edges
    #
    # @example
    #   graph.number_of_edges
    def number_of_edges
      @adj.values.flat_map(&:values).map(&:length).inject(:+) / 2
    end

    # Checks if the the edge consisting of two nodes is present in the graph
    #
    # @example
    #   graph.edge?(node_1, node_2)
    #
    # @param node_1 [Object] the first node of the edge to be checked
    # @param node_2 [Object] the second node of the edge to be checked
    # @param key [Integer] the key of the given edge
    def edge?(node_1, node_2, key=nil)
      super(node_1, node_2) if key.nil?
      node?(node_1) && @adj[node_1].key?(node_2) && @adj[node_1][node_2].key?(key)
    end

    # Returns the undirected version of the graph
    #
    # @example
    #   graph.to_undirected
    def to_undirected
      graph = NetworkX::Graph.new(**@graph)
      @nodes.each { |node, node_attr| graph.add_node(node, **node_attr) }
      @adj.each do |node_1, node_1_edges|
        node_1_edges.each do |node_2, node_1_node_2|
          edge_attrs = {}
          node_1_node_2.each { |_key, attrs| edge_attrs.merge!(attrs) }
          graph.add_edge(node_1, node_2, **edge_attrs)
        end
      end
      graph
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
        sub_graph = NetworkX::MultiGraph.new(**@graph)
        nodes.each do |u, _|
          raise KeyError, "#{u} does not exist in the current graph!" unless @nodes.key?(u)

          sub_graph.add_node(u, **@nodes[u])
          @adj[u].each do |v, edge_val|
            edge_val.each { |_, keyval| sub_graph.add_edge(u, v, **keyval) if @adj[u].key?(v) && nodes.include?(v) }
          end
          return sub_graph
        end
      else
        raise ArgumentError, 'Expected Argument to be Array or Set of nodes, '\
                             "received #{nodes.class.name} instead."
      end
    end

    # TODO: Reduce method complexity and method length

    # Returns subgraph conisting of given edges
    #
    # @example
    #   graph.edge_subgraph([%w[Nagpur Wardha], %w[Nagpur Mumbai]])
    #
    # @param edges [Array<Object, Object>] the edges to be included in the subraph
    def edge_subgraph(edges)
      case edges
      when Array, Set
        sub_graph = NetworkX::MultiGraph.new(**@graph)
        edges.each do |u, v|
          raise KeyError, "Edge between #{u} and #{v} does not exist in the graph!" unless @nodes.key?(u)\
                                                                                    && @adj[u].key?(v)

          sub_graph.add_node(u, **@nodes[u])
          sub_graph.add_node(v, **@nodes[v])
          @adj[u][v].each { |_, keyval| sub_graph.add_edge(u, v, **keyval) }
        end
        return sub_graph
      else
        raise ArgumentError, 'Expected Argument to be Array or Set of edges, '\
        "received #{edges.class.name} instead."
      end
    end
  end
end
