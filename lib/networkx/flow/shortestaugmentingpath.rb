module NetworkX
  def self.shortest_augmenting_path_impl(graph, source, target, residual, two_phase, cutoff)
    raise ArgumentError, 'Source is not in the graph!' unless graph.nodes.key?(source)
    raise ArgumentError, 'Target is not in the graph!' unless graph.nodes.key?(target)
    raise ArgumentError, 'Source and Target are the same!' if source == target

    residual = residual.nil? ? build_residual_network(graph) : residual
    r_nodes = residual.nodes
    r_pred = residual.pred
    r_adj = residual.adj

    r_adj.each do |u, u_edges|
      u_edges.each do |v, attrs|
        attrs[:flow] = 0
      end
    end

    heights = {target => 0}
    q = [[target, 0]]

    while !q.empty?
      u, height = q.shift
      height += 1
      r_pred[u].each do |v, attrs|
        if !heights.key?(v) && attrs[:flow] < attrs[:capacity]
          heights[v] = height
          q << [v, height]
        end
      end
    end

    unless heights.key?(source)
      residual.graph[:flow_value] = 0
      return residual
    end

    n = graph.nodes.length
    m = residual.size / 2

    r_nodes.each do |u, attrs|
      attrs[:height] = heights.key?(u) ? heights[u] : n
      attrs[:curr_edge] = CurrentEdge.new(r_adj[u])
    end

    counts = Array.new(2 * n - 1, 0)
    counts.fill(0)
    r_nodes.each { |u, attrs| counts[attrs[:height]] += 1 }
    inf = graph.graph[:inf]

    cutoff = Float::INFINITY if cutoff.nil?
    flow_value = 0
    path = [source]
    u = source
    d = two_phase ? n : [m ** 0.5, 2 * n ** (2. / 3)].min.floor
    done = r_nodes[source][:height] >= d

    while !done
      height = r_nodes[u][:height]
      curr_edge = r_nodes[u][:curr_edge]

      while true
        v, attr = curr_edge.get
        if height == r_nodes[v][:height] + 1 && attr[:flow] < attr[:capacity]
          path << v
          u = v
          break
        end
        begin
          curr_edge.move_to_next
        rescue StopIteration
          if counts[height] == 0
            residual.graph[:flow_value] = flow_value
            return residual
          end
          height = relabel(u, n, r_adj, r_nodes)
          if u == source && height >= d
            if !two_phase
              residual.graph[:flow_value] = flow_value
              return residual
            else
              done = true
              break
            end
          end
          counts[height] += 1
          r_nodes[u][:height] = height
          unless u == source
            path.pop
            u = path[-1]
            break
          end
        end
      end
      if u == target
        flow_value += augment(path, inf, r_adj)
        if flow_value >= cutoff
          residual.graph[:flow_value] = flow_value
          return residual
        end
      end
    end
    flow_value += edmondskarp_core(residual, source, target, cutoff - flow_value)
    residual.graph[:flow_value] = flow_value
    residual
  end

  def augment(path, inf, r_adj)
    flow = inf
    temp_path = path.clone
    u = temp_path.shift
    temp_path.each do |v|
      attr = r_adj[u][v]
      flow = [flow, attr[:capacity] - attr[:flow]].min
      u = v
    end
    raise ArgumentError, 'Infinite capacity path!' if flow * 2 > inf
    temp_path = path.clone
    u = temp_path.shift
    temp_path.each do |v|
      r_adj[u][v][:flow] += flow
      r_adj[v][u][:flow] -= flow
      u = v
    end
    flow
  end

  def self.relabel(u, n, r_adj, r_nodes)
    height = n - 1
    r_adj[u].each do |v, attrs|
      height = [height, r_nodes[v][:height]].min if attrs[:flow] < attrs[:capacity]
    end
    height + 1
  end

  def self.shortest_augmenting_path(graph, source, target, residual=nil, value_only=false, two_phase=false, cutoff=nil)
    shortest_augmenting_path_impl(graph, source, target, residual, two_phase, cutoff)
  end
end