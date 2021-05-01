module NetworkX
  # Describes the class for making Undirected Graphs
  #
  # @attr_reader adj [Hash{ Object => Hash{ Object => Hash{ Object => Object } } }]
  #                  Stores the edges and their attributes in an adjencency list form
  # @attr_reader nodes [Hash{ Object => Hash{ Object => Object } }] Stores the nodes and their attributes
  # @attr_reader graph [Hash{ Object => Object }] Stores the attributes of the graph
  class Graph
    attr_reader :adj, :nodes, :graph

    # Constructor for initializing graph
    #
    # @example Initialize a graph with attributes 'type' and 'name'
    #   graph = NetworkX::Graph.new(name: "Social Network", type: "undirected")
    #
    # @param graph_attrs [Hash{ Object => Object }] the graph attributes in a hash format
    def initialize(**graph_attrs)
      @nodes = {}
      @adj = {}
      @graph = {}

      @graph = graph_attrs
    end

    # Adds the respective edges
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
      @adj[node_2][node_1] = edge_attrs
    end

    # Adds multiple edges from an array
    #
    # @example Add multiple edges without any attributes
    #   graph.add_edges([['Nagpur', 'Kgp'], ['Noida', 'Kgp']])
    # @param edges [Array<Object, Object>]
    def add_edges(edges)
      case edges
      when Array
        edges.each { |node_1, node_2, **attrs| add_edge(node_1, node_2, attrs) }
      else
        raise ArgumentError, 'Expected argument to be an Array of edges, '\
                             "received #{edges.class.name} instead."
      end
    end

    # Adds a node and its attributes to the graph
    #
    # @example Add a node with attribute 'type'
    #   graph.add_node("Noida", type: "city")
    #
    # @param node [Object] the node object
    # @param node_attrs [Hash{ Object => Object }] the hash of the attributes of the node
    def add_node(node, **node_attrs)
      if @nodes.key?(node)
        @nodes[node].merge!(node_attrs)
      else
        @adj[node] = {}
        @nodes[node] = node_attrs
      end
    end

    # Adds multiple nodes to the graph
    #
    # @example Adds multiple nodes with attribute 'type'
    #   graph.add_nodes([["Noida", type: "city"], ["Kgp", type: "town"]])
    #
    # @param nodes [Array<Object, Hash{ Object => Object }>] the Array of pair containing nodes and its attributes
    def add_nodes(nodes)
      case nodes
      when Set, Array
        nodes.each { |node, **node_attrs| add_node(node, node_attrs) }
      else
        raise ArgumentError, 'Expected argument to be an Array or Set of nodes, '\
                             "received #{nodes.class.name} instead."
      end
    end

    # Removes node from the graph
    #
    # @example
    #   graph.remove_node("Noida")
    #
    # @param node [Object] the node to be removed
    def remove_node(node)
      raise KeyError, "Error in deleting node #{node} from Graph." unless @nodes.key?(node)

      @adj[node].each_key { |k| @adj[k].delete(node) }
      @adj.delete(node)
      @nodes.delete(node)
    end

    # Removes multiple nodes from the graph
    #
    # @example
    #   graph.remove_nodes(["Noida", "Bangalore"])
    #
    # @param nodes [Array<Object>] the array of nodes to be removed
    def remove_nodes(nodes)
      case nodes
      when Set, Array
        nodes.each { |node| remove_node(node) }
      else
        raise ArgumentError, 'Expected argument to be an Array or Set of nodes, '\
                             "received #{nodes.class.name} instead."
      end
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
      @adj[node_2].delete(node_1) if node_1 != node_2
    end

    # Removes multiple edges from the graph
    #
    # @example
    #   graph.remove_edges([%w[Noida Bangalore], %w[Bangalore Chennai]])
    #
    # @param edges [Array<Object>] the array of edges to be removed
    def remove_edges(edges)
      case edges
      when Array, Set
        edges.each { |node_1, node_2| remove_edge(node_1, node_2) }
      else
        raise ArgumentError, 'Expected Arguement to be Array or Set of edges, '\
                             "received #{edges.class.name} instead."
      end
    end

    # Adds weighted edge
    #
    # @example
    #   graph.add_weighted_edge('Noida', 'Bangalore', 1000)
    #
    # @param node_1 [Object] the first node of the edge
    # @param node_2 [Object] the second node of the edge
    # @param weight [Integer] the weight value
    def add_weighted_edge(node_1, node_2, weight)
      add_edge(node_1, node_2, weight: weight)
    end

    # Adds multiple weighted edges
    #
    # @example
    #   graph.add_weighted_edges([['Noida', 'Bangalore'],
    #                             ['Noida', 'Nagpur']], [1000, 2000])
    #
    # @param edges [Array<Object, Object>] the array of edges
    # @param weights [Array<Integer>] the array of weights
    def add_weighted_edges(edges, weights)
      raise ArgumentError, 'edges and weights array must have equal number of elements.'\
                           unless edges.size == weights.size
      raise ArgumentError, 'edges and weight must be given in an Array.'\
                           unless edges.is_a?(Array) && weights.is_a?(Array)

      (edges.transpose << weights).transpose.each do |node_1, node_2, weight|
        add_weighted_edge(node_1, node_2, weight)
      end
    end

    # Clears the graph
    #
    # @example
    #   graph.clear
    def clear
      @adj.clear
      @nodes.clear
      @graph.clear
    end

    # Checks if a node is present in the graph
    #
    # @example
    #   graph.node?(node_1)
    #
    # @param node [Object] the node to be checked
    def node?(node)
      @nodes.key?(node)
    end

    # Checks if the the edge consisting of two nodes is present in the graph
    #
    # @example
    #   graph.edge?(node_1, node_2)
    #
    # @param node_1 [Object] the first node of the edge to be checked
    # @param node_2 [Object] the second node of the edge to be checked
    def edge?(node_1, node_2)
      node?(node_1) && @adj[node_1].key?(node_2)
    end

    # Gets the node data
    #
    # @example
    #   graph.get_node_data(node)
    #
    # @param node [Object] the node whose data is to be fetched
    def get_node_data(node)
      raise ArgumentError, 'No such node exists!' unless node?(node)

      @nodes[node]
    end

    # Gets the edge data
    #
    # @example
    #   graph.get_edge_data(node_1, node_2)
    #
    # @param node_1 [Object] the first node of the edge
    # @param node_2 [Object] the second node of the edge
    def get_edge_data(node_1, node_2)
      raise KeyError, 'No such edge exists!' unless node?(node_1) && node?(node_2)

      @adj[node_1][node_2]
    end

    # Retus a hash of neighbours of a node
    #
    # @example
    #   graph.neighbours(node)
    #
    # @param node [Object] the node whose neighbours are to be fetched
    def neighbours(node)
      raise KeyError, 'No such node exists!' unless node?(node)

      @adj[node]
    end

    # Returns number of nodes
    #
    # @example
    #   graph.number_of_nodes
    def number_of_nodes
      @nodes.length
    end

    # Returns number of edges
    #
    # @example
    #   graph.number_of_edges
    def number_of_edges
      @adj.values.map(&:length).inject(:+) / 2
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
          hash_val.each { |_, v| graph_size += v[:weight] if v.key?(:weight) }
        end
        return graph_size / 2
      end
      number_of_edges
    end

    # TODO: Reduce method length and method complexity

    # Returns subgraph consisting of given array of nodes
    #
    # @example
    #   graph.subgraph(%w[Mumbai Nagpur])
    #
    # @param nodes [Array<Object>] the nodes to be included in the subgraph
    def subgraph(nodes)
      case nodes
      when Array, Set
        sub_graph = NetworkX::Graph.new(@graph)
        nodes.each do |u, _|
          raise KeyError, "#{u} does not exist in the current graph!" unless @nodes.key?(u)

          sub_graph.add_node(u, @nodes[u])
          @adj[u].each do |v, edge_val|
            sub_graph.add_edge(u, v, edge_val) if @adj[u].key?(v) && nodes.include?(v)
          end
          return sub_graph
        end
      else
        raise ArgumentError, 'Expected Argument to be Array or Set of nodes, '\
                             "received #{nodes.class.name} instead."
      end
    end

    # TODO: Reduce method length and method complexity

    # Returns subgraph conisting of given edges
    #
    # @example
    #   graph.edge_subgraph([%w[Nagpur Wardha], %w[Nagpur Mumbai]])
    #
    # @param edges [Array<Object, Object>] the edges to be included in the subraph
    def edge_subgraph(edges)
      case edges
      when Array, Set
        sub_graph = NetworkX::Graph.new(@graph)
        edges.each do |u, v|
          raise KeyError, "Edge between #{u} and #{v} does not exist in the graph!" unless @nodes.key?(u)\
                                                                                    && @adj[u].key?(v)

          sub_graph.add_node(u, @nodes[u])
          sub_graph.add_node(v, @nodes[v])
          sub_graph.add_edge(u, v, @adj[u][v])
        end
        return sub_graph
      else
        raise ArgumentError, 'Expected Argument to be Array or Set of edges, '\
        "received #{edges.class.name} instead."
      end
    end

    def multigraph?
      ['NetworkX::MultiGraph', 'NetworkX::MultiDiGraph'].include?(self.class.name)
    end

    def directed?
      ['NetworkX::DiGraph', 'NetworkX::MultiDiGraph'].include?(self.class.name)
    end
  end
end
