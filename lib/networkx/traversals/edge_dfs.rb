module NetworkX
  # TODO: Reduce method complexity and method length

  # Helper function for edge_dfs
  #
  # @param graph [Graph, DiGraph, MultiGraph, MultiDiGraph] a graph
  # @param node [Object] a node in the graph
  def self.out_edges(graph, node)
    edges = []
    visited = {}
    case graph.class.name
    when 'NetworkX::Graph', 'NetworkX::DiGraph'
      graph.adj[node].each do |v, _|
        if graph.class.name == 'NetworkX::DiGraph' || visited[[v, node]].nil?
          visited[[node, v]] = true
          edges << [node, v]
        end
      end
    else
      graph.adj[node].each do |v, uv_keys|
        uv_keys.each_key do |k|
          if graph.class.name == 'NetworkX::MultiDiGraph' || visited[[v, node, k]].nil?
            visited[[node, v, k]] = true
            edges << [node, v, k]
          end
        end
      end
    end
    edges
  end

  # Helper function of edge_dfs
  def self.edge_id(graph, edge)
    return edge if graph.directed?
    return Set.new([edge, (edge[0..1].reverse + edge[2])]) if graph.multigraph?

    Set.new([edge, edge.reverse])
  end

  # TODO: Reduce method complexity and method length

  # Performs edge dfs on the graph
  # Orientation :ignore, directed edges can be
  #                     travelled in both fashions
  # Orientation reverse, directed edges can be travelled
  #                      in reverse fashion
  # Orientation :nil, the graph is not meddled with
  #
  # @example
  #   NetworkX.edge_dfs(graph, source, 'ignore')
  #
  # @param graph [Graph, DiGraph, MultiGraph, MultiDiGraph] a graph
  # @param source [Object] node to start dfs from
  # @param orientation [:ignore, :reverse', nil] the orientation of edges of graph
  def self.edge_dfs(graph, start, orientation=nil)
    case orientation
    when :reverse
      graph = graph.reverse if graph.class.name == 'NetworkX::DiGraph' || graph.class.name == 'NetworkX::MultiDiGraph'
    when :ignore
      graph = graph.to_undirected if graph.class.name == 'NetworkX::DiGraph'
      graph = graph.to_multigraph if graph.class.name == 'NetworkX::MultiDiGraph'
    end

    visited_edges = []
    visited_nodes = []
    stack = [start]
    current_edges = {}

    e = Enumerator.new do |yield_var|
      until stack.empty?
        current = stack.last
        unless visited_nodes.include?(current)
          current_edges[current] = out_edges(graph, current)
          visited_nodes << current
        end

        edge = current_edges[current].shift
        if edge.nil?
          stack.pop
        else
          unless visited_edges.include?(edge_id(graph, edge))
            visited_edges << edge_id(graph, edge)
            stack << edge[1]
            yield_var.yield edge
          end
        end
      end
    end
    e.take(graph.number_of_edges)
  end
end
