module IntervalBasedForest

using DecisionTree: DecisionTreeClassifier, fit!, apply_tree_proba, build_tree, Node
using Statistics

function TimeSeriesForestClassifier(m, X, y)
    min_interval = m.min_interval
    n_trees = m.n_trees
    transform_xt, intervals = InvFeatureGen(X, n_trees, min_interval)
    forest = Array{Node,1}()
    for i in range(1, stop=n_trees)
        mdl = build_tree(y, transform_xt[i],
                         m.n_subfeatures,
                         m.max_depth,
                         m.min_samples_leaf,
                         m.min_samples_split,
                         m.min_purity_increase)
        push!(forest, mdl)
    end
    forest, intervals
end

function predict_new(X1, forest, intervals, integers_seen)
    n_instance, s_length = size(X1)
    n_trees = length(forest)
    X1 = InvFeatureGen(X1, intervals, n_trees)
    sum = zeros(n_instance, length(integers_seen))
    for i=1:n_trees
        sum += apply_tree_proba(forest[i], X1[i], integers_seen)
    end
    return sum/n_trees
end

function InvFeatureGen(X, n_trees::Int, min_interval::Int)
    n_samps, series_length = size(X)
    transform_xt = Array{Array{Float64,2},1}()
    n_intervals = floor(Int, sqrt(series_length))
    intervals = zeros(Int, n_trees, 3*n_intervals, 2)
    for i in range(1, stop = n_trees)
       transformed_x = Array{Float64,2}(undef, 3*n_intervals, n_samps)
       for j in range(1, stop = n_intervals)
           intervals[i,j,1] = rand(1:(series_length - min_interval))
           len = rand(1:(series_length - intervals[i,j,1]))
           if len < min_interval
               len = min_interval
           end
           intervals[i,j,2] = intervals[i,j,1] + len
           Y = X[:, intervals[i,j,1]:intervals[i,j,2]]
           x = Array(1:size(Y)[2])
           means = mean(Y, dims=2)
           stds =  std(Y, dims=2)
           slope = (mean(transpose(x).*Y, dims=2) -
                    mean(x)*mean(Y, dims=2)) / (mean(x.*x) - mean(x)^2)
           transformed_x[3*j-2,:] =  means
           transformed_x[3*j-1,:] =  stds
           transformed_x[3*j,:]   =  slope
       end
           push!(transform_xt, transpose(transformed_x))
    end
    return transform_xt, intervals
end

function InvFeatureGen(X, intervals::Array, n_trees::Int)
    n_samps, series_length = size(X)
    transform_xt = Array{Array{Float64,2},1}()
    n_intervals = floor(Int, sqrt(series_length))
    for i in range(1, stop = n_trees)
       transformed_x = Array{Float64,2}(undef, 3*n_intervals, n_samps)
       for j in range(1, stop = n_intervals)
           Y = X[:, intervals[i,j,1]:intervals[i,j,2]]
           x = Array(1:size(Y)[2])
           means = mean(Y, dims=2)
           stds =  std(Y, dims=2)
           slope = (mean(transpose(x).*Y, dims=2) -
                    mean(x)*mean(Y, dims=2)) / (mean(x.*x) - mean(x)^2)
           transformed_x[3*j-2,:] =  means
           transformed_x[3*j-1,:] =  stds
           transformed_x[3*j,:]   =  slope
       end
           push!(transform_xt, transpose(transformed_x))
    end
    return transform_xt
end

end # TimeSeriesForestClassifier
