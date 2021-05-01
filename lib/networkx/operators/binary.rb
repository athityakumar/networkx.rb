# TODO: Reduce module length

module NetworkX
  # Returns the edges of the graph in an array
  def self.get_edges(graph)
    edges = []
    graph.adj.each do |u, u_attrs|
      u_attrs.each do |v, uv_attrs|
        edges << [u, v, uv_attrs]
      end
    end
    edges
  end

  # TODO: Reduce method complexity and method length

  # Transforms the labels of the nodes of the graphs
  # so that they are disjoint.
  def self.convert_to_distinct_labels(graph, starting_int=-1)
    new_graph = Marshal.load(Marshal.dump(graph))
    new_graph.clear

    idx_dict = Hash[graph.nodes.keys.map do |v|
      starting_int += 1
      [v, starting_int]
    end]

    graph.nodes.each do |u, attrs|
      new_graph.add_node(u.to_s + idx_dict[u].to_s, **attrs)
    end

    graph.adj.each do |u, u_edges|
      u_edges.each do |v, uv_attrs|
        if graph.multigraph?
          uv_attrs.each do |_k, attrs|
            new_graph.add_edge(u.to_s + idx_dict[u].to_s, v.to_s + idx_dict[v].to_s, **attrs)
          end
        else
          new_graph.add_edge(u.to_s + idx_dict[u].to_s, v.to_s + idx_dict[v].to_s, **uv_attrs)
        end
      end
    end
    new_graph
  end

  # TODO: Reduce method complexity and method length

  # Performs the intersection of two graphs
  #
  # @param [Graph, DiGraph, MultiGraph, MultiDiGraph] graph no.1
  # @param [Graph, DiGraph, MultiGraph, MultiDiGraph] graph no.2
  #
  # @return [Graph, DiGraph, MultiGraph, MultiDiGraph] the intersection of the two graphs
  def self.intersection(g_1, g_2)
    result = Marshal.load(Marshal.dump(g_1))
    result.clear

    raise ArgumentError, 'Arguments must be both Graphs or MultiGraphs!' unless g_1.multigraph? == g_2.multigraph?
    raise ArgumentError, 'Node sets must be equal!' unless (g_1.nodes.keys - g_2.nodes.keys).empty?

    g_1.nodes.each { |u, attrs| result.add_node(u, **attrs) }

    if g_1.number_of_edges <= g_2.number_of_edges
      g_1.adj.each do |u, u_edges|
        u_edges.each do |v, uv_attrs|
          if g_1.multigraph?
            uv_attrs.each do |k, attrs|
              result.add_edge(u, v, **attrs) if g_2.edge?(u, v, k)
            end
          elsif g_2.edge?(u, v)
            result.add_edge(u, v, **uv_attrs)
          end
        end
      end
    else
      g_2.adj.each do |u, u_edges|
        u_edges.each do |v, uv_attrs|
          if g_2.multigraph?
            uv_attrs.each do |k, attrs|
              result.add_edge(u, v, **attrs) if g_1.edge?(u, v, k)
            end
          elsif g_1.edge?(u, v)
            result.add_edge(u, v, uv_attrs)
          end
        end
      end
    end
    result
  end

  # TODO: Reduce method complexity and method length

  # Performs the difference of two graphs
  #
  # @param [Graph, DiGraph, MultiGraph, MultiDiGraph] graph no.1
  # @param [Graph, DiGraph, MultiGraph, MultiDiGraph] graph no.2
  #
  # @return [Graph, DiGraph, MultiGraph, MultiDiGraph] the difference of the two graphs
  def self.difference(g_1, g_2)
    result = Marshal.load(Marshal.dump(g_1))
    result.clear

    raise ArgumentError, 'Arguments must be both Graphs or MultiGraphs!' unless g_1.multigraph? == g_2.multigraph?
    raise ArgumentError, 'Node sets must be equal!' unless (g_1.nodes.keys - g_2.nodes.keys).empty?

    g_1.nodes.each { |u, attrs| result.add_node(u, **attrs) }

    g_1.adj.each do |u, u_edges|
      u_edges.each do |v, uv_attrs|
        if g_1.multigraph?
          uv_attrs.each do |k, attrs|
            result.add_edge(u, v, **attrs) unless g_2.edge?(u, v, k)
          end
        else
          result.add_edge(u, v, **uv_attrs) unless g_2.edge?(u, v)
        end
      end
    end
    result
  end

  # TODO: Reduce method complexity and method length

  # Performs the symmetric difference of two graphs
  #
  # @param [Graph, DiGraph, MultiGraph, MultiDiGraph] graph no.1
  # @param [Graph, DiGraph, MultiGraph, MultiDiGraph] graph no.2
  #
  # @return [Graph, DiGraph, MultiGraph, MultiDiGraph] the symmetric difference of the two graphs
  def self.symmetric_difference(g_1, g_2)
    result = Marshal.load(Marshal.dump(g_1))
    result.clear

    raise ArgumentError, 'Arguments must be both Graphs or MultiGraphs!' unless g_1.multigraph? == g_2.multigraph?
    raise ArgumentError, 'Node sets must be equal!' unless (g_1.nodes.keys - g_2.nodes.keys).empty?

    g_1.nodes.each { |u, attrs| result.add_node(u, **attrs) }

    g_1.adj.each do |u, u_edges|
      u_edges.each do |v, uv_attrs|
        if g_1.multigraph?
          uv_attrs.each do |k, attrs|
            result.add_edge(u, v, **attrs) unless g_2.edge?(u, v, k)
          end
        else
          result.add_edge(u, v, **uv_attrs) unless g_2.edge?(u, v)
        end
      end
    end

    g_2.adj.each do |u, u_edges|
      u_edges.each do |v, uv_attrs|
        if g_2.multigraph?
          uv_attrs.each do |k, attrs|
            result.add_edge(u, v, **attrs) unless g_1.edge?(u, v, k)
          end
        else
          result.add_edge(u, v, **uv_attrs) unless g_1.edge?(u, v)
        end
      end
    end
    result
  end

  # TODO: Reduce method complexity and method length

  # Performs the composition of two graphs
  #
  # @param [Graph, DiGraph, MultiGraph, MultiDiGraph] graph no.1
  # @param [Graph, DiGraph, MultiGraph, MultiDiGraph] graph no.2
  #
  # @return [Graph, DiGraph, MultiGraph, MultiDiGraph] the composition of the two graphs
  def self.compose(g_1, g_2)
    result = Marshal.load(Marshal.dump(g_1))
    result.clear

    raise ArgumentError, 'Arguments must be both Graphs or MultiGraphs!' unless g_1.multigraph? == g_2.multigraph?

    result.add_nodes(g_1.nodes.map { |u, attrs| [u, attrs] })
    result.add_nodes(g_2.nodes.map { |u, attrs| [u, attrs] })

    if g_1.multigraph?
      g_1.adj.each { |u, e| e.each { |v, uv_edges| uv_edges.each_value { |attrs| result.add_edge(u, v, **attrs) } } }
      g_2.adj.each { |u, e| e.each { |v, uv_edges| uv_edges.each_value { |attrs| result.add_edge(u, v, **attrs) } } }
    else
      g_1.adj.each { |u, u_edges| u_edges.each { |v, attrs| result.add_edge(u, v, **attrs) } }
      g_2.adj.each { |u, u_edges| u_edges.each { |v, attrs| result.add_edge(u, v, **attrs) } }
    end
    result
  end

  # TODO: Reduce method complexity and method length

  # Performs the union of two graphs
  #
  # @param [Graph, DiGraph, MultiGraph, MultiDiGraph] graph no.1
  # @param [Graph, DiGraph, MultiGraph, MultiDiGraph] graph no.2
  #
  # @return [Graph, DiGraph, MultiGraph, MultiDiGraph] the union of the two graphs
  def self.union(g_1, g_2)
    raise ArgumentError, 'Arguments must be both Graphs or MultiGraphs!' unless g_1.multigraph? == g_2.multigraph?

    case g_1
    when NetworkX::MultiGraph
      new_graph = NetworkX::MultiGraph.new
    when NetworkX::MultiDiGraph
      new_graph = NetworkX::MultiDiGraph.new
    when NetworkX::Graph
      new_graph = NetworkX::Graph.new
    when NetworkX::DiGraph
      new_graph = NetworkX::DiGraph.new
    end

    new_graph.graph.merge!(g_1.graph)
    new_graph.graph.merge!(g_2.graph)

    raise ArgumentError, 'Graphs must be disjoint!' unless (g_1.nodes.keys & g_2.nodes.keys).empty?

    g1_edges = get_edges(g_1)
    g2_edges = get_edges(g_2)

    new_graph.add_nodes(g_1.nodes.keys)
    new_graph.add_edges(g1_edges)
    new_graph.add_nodes(g_2.nodes.keys)
    new_graph.add_edges(g2_edges)

    new_graph
  end

  # Performs the disjoint union of two graphs
  #
  # @param [Graph, DiGraph, MultiGraph, MultiDiGraph] graph no.1
  # @param [Graph, DiGraph, MultiGraph, MultiDiGraph] graph no.2
  #
  # @return [Graph, DiGraph, MultiGraph, MultiDiGraph] the disjoint union of the two graphs
  def self.disjoint_union(g_1, g_2)
    new_g_1 = convert_to_distinct_labels(g_1)
    new_g_2 = convert_to_distinct_labels(g_2)
    result = union(new_g_1, new_g_2)
    result.graph.merge!(g_1.graph)
    result.graph.merge!(g_2.graph)
    result
  end
end
