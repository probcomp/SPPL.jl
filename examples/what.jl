struct Foo{T,L<:String}
    a::T
end
# Foo{L}(a::T) where {T,L} = Foo{T,L}(a)
Foo{String}(1)
