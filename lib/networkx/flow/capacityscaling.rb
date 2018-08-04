module NetworkX
  def self.generate_unique_node
    SecureRandom.uuid
  end

  def self._detect_unboundedness(residual)
    s = generate_unique_node
    g = NetworkX::DiGraph.new
    g.add_nodes(residual.nodes.keys.zip(residual.nodes.values))
    inf = residual.graph[:inf]

    residual.nodes.each do |u, attr|
      residual.adj[u].each do |v, uv_attrs|
        w = inf
        uv_attrs.each { |key, edge_attrs| w = [w, edge_attrs[:weight]].min if edge_attrs[:capacity] == inf }
        g.add_edge(u, v, weight: w) unless w != inf
      end
    end

    # TODO: Detect negative edges
  end

  def self._build_residual_network(graph)
    raise ArgumentError, 'Sum of demands should be 0!' unless graph.nodes.values.map { |attr| attr[:demand] || 0 }.inject(0, :+) == 0
    residual = NetworkX::MultiDiGraph.new(inf: 0)
    residual.add_nodes(graph.nodes.map { |u, attr| [u, excess: (attr[:demand] || 0) * -1, potential: 0] })
    inf = Float::INFINITY
    edge_list = []

    # TODO: Selfloop edges check

    if graph.multigraph?
      graph.adj.each do |u, u_edges|
        u_edges.each do |v, uv_edges|
          uv_edges.each do |k, attrs|
            edge_list << [u, v, k, e] if u != v && (attrs[:capacity] || inf) > 0
          end
        end
      end
    else
      graph.adj.each do |u, u_edges|
        u_edges.each do |v, attrs|
          edge_list << [u, v, 0, attrs] if u != v && (attrs[:capacity] || inf) > 0
        end
      end
    end

    temp_inf = [residual.nodes.map { |u, attrs| attrs[:excess].abs }.inject(0, :+), edge_list.map { |_, _, _, e| (e.key?(:capacity) && e[:capacity] != inf ? e[:capacity] : 0) }.inject(0, :+) * 2].max
    inf = temp_inf == 0 ? 1 : temp_inf

    edge_list.each do |u, v, k, e|
      r = [e[:capacity] || inf, inf].min
      w = e[:weight] || 0
      residual.add_edge(u, v, temp_key: [k, true], capacity: r, weight: w, flow: 0)
      residual.add_edge(v, u, temp_key: [k, false], capacity: 0, weight: -w, flow: 0)
    end
    residual.graph[:inf] = inf
    _detect_unboundedness(residual)
    residual
  end

  def self._build_flow_dict(graph, residual)
    flow_dict = {}
    inf = Float::INFINITY

    if graph.multigraph?
      graph.nodes.each do |u, _|
        flow_dict[u] = {}
        graph.adj[u].each do |u, uv_edges|
          flow_dict[u][v] = Hash[uv_edges.map { |k, e| [k, u != v || (e[:capacity] || inf) <= 0 || (e[:weight] || 0) >= 0 ? 0 : e[:capacity]] }]
        end
        residual.adj[u].each do |v, uv_edges|
          flow_dict[u][v].merge!(Hash[uv_edges.map { |k, attrs| [attrs[:temp_key][0], attrs[:flow]] if attrs[:flow] > 0 }])
        end
      end
    else
      graph.nodes.each do |u, _|
        flow_dict[u] = Hash[graph.adj[u].map { |v, e| [v, u != v || (e[:capacity] || inf) <= 0 || (e[:weight] || 0) >= 0 ? 0 : e[:capacity]] }]
        merge_dict = {}
        residual.adj[u].each { |v, uv_edges| uv_edges.each { |_, attrs| merge_dict[v] = attrs[:flow] if attrs[:flow] > 0 } }
        flow_dict[u].merge!(merge_dict)
      end
    end
    flow_dict
  end

  cnt = 0
  def self.count
    cnt += 1
    cnt
  end

  def self.capacity_scaling(graph)
    residual = build_residual_network(graph)
    inf = Float::INFINITY
    flow_cost = 0

    # TODO: Account cost of self-loof edges

    wmax = ([-inf] + residual.adj.inject([]) do |arr, u|
        arr += u[1][:capacity]
        arr
      end).max

    return flow_cost, _build_flow_dict(graph, residual) if wmax == -inf
    r_nodes = residual.nodes
    r_adj = residual.adj

    delta = 2 ** Math.log2(wmax).floor
    while delta >= 1
      r_nodes.each do |u, u_attrs|
        p_u = attrs[:potential]
        r_adj[u].each do |v, uv_edges|
          uv_edges.each do |k, e|
            flow = e[:capacity]
            if e[:weight] - p_u + r_nodes[v][:potential] < 0
              flow = e[:capacity] - e[:flow]
              if flow >= delta
                e[:flow] += flow
                r_adj[v][u].each_key { |attrs| attrs[:flow] += attrs[:temp_key][0] == e[:temp_key][0] && attrs[:temp_key][1] != e[:temp_key][1] ? -flow : 0 }
                r_nodes[u][:excess] -= flow
                r_nodes[v][:excess] += flow
              end
            end
          end
        end
      end

      s_set = Set.new
      t_set = Set.new

      residual.nodes.each do |u, attrs|
        excess = r_nodes[u][:excess]
        if excess >= delta
          s_set.add(u)
        elsif excess <= -delta
          t_set.add(u)
        end
      end

      while !s.empty? && !t.empty?
        s = arbitrary_element()
        t = nil
        d = {}
        pred = {s => nil}
        h = Heap.new { |x, y| x[0] < y[0] || (x[0] == y[0] && x[1] < y[1]) }
        h_dict = {s => 0}
        h << [0, count, s]
        while !h.empty?
          d_u, _, u = h.pop
          h_dict.delete(u)
          d[u] = d_u
          if t_set.include?(u)
            t = u
            break
          end
          p_u = r_nodes[u][:potential]
          r_adj[u].each do |v, uv_edges|
            next if d.key?(v)
            wmin = inf
            uv_edges.each do |k, e|
              if e[:capacity] - e[:flow] >= delta
                w = e[:weight]
                if w < wmin
                  wmin = w
                  kmin = e[:temp_key]
                  emin = e
                end
              end
            end
            next if wmin == inf
            d_v = d_u + wmin - p_u + r_nodes[v][:potential]
            if h_dict[v] > d_v
              h << [d_v, count, v]
              h_dict[v] = d_v
              pred[v] = [u, kmin, emin]
            end
          end
        end

        if !t.nil?
          while u != s
            v = u
            u, k, e = pred[v]
            e[:flow] += delta
            r_adj[v][u].each_key { |attrs| attrs[:flow] += (attrs[:temp_key][0] == k[0] && attrs[:temp_key][1] != k[1]) ? -delta : 0 }
          end
          r_nodes[s][:excess] -= delta
          r_nodes[t][:excess] += delta
          s_set.delete(s) if r_nodes[s][:excess] < delta
          t_set.delete(t) if r_nodes[t][:excess] > -delta
          d_t = d[t]
          d.each { |u, d_u| r_nodes[u][:potential] -= (d_u - d_t) }
        else
          s_set.delete(s)
        end
      end
      delta  = (delta / 2).floor
    end

    r_nodes.each { |u, attrs| raise ArgumentError, 'No flow satisfying all demands!' if attrs[:excess] != 0 }

    residual.nodes.each do |u, attrs|
      residual.adj[u].each do |v, uv_edges|
        uv_edges.each do |k, k_attrs|
          flow = k_attrs[:flow]
          flow_cost += (flow * k_attrs[:weight])
        end
      end
    end
    [flow_cost, _build_flow_dict(graph, residual)]
  end
end