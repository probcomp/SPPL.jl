struct DisjointIntervals{T}
end

function sample(intervals::DisjointIntervals)
    i = 1
    p = intervals.probs
    n = length(p)
    i = 1
    c = p[1]
    u = rand()
    while c < u && i < n
        c += p[i+=1]
    end
    return i
end

export DisjointIntervals, sample
