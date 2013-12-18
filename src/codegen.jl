# facilities for code generation


type ArgInfo{AN} end

arginfo(n::Int) = ArgInfo{n}()

immutable CodegenHelper
	aparams::Vector{Expr}
	args::Vector{Symbol}
	offset_args::Vector
	term::Expr
	inputsize::Expr
	termtype::Expr
end

function codegen_helper(::ArgInfo{0})
	aparams = [:(a::ContiguousArray)]
	args = [:a]
	offset_args = [:(offset_view(a, ao, m, n))]
	term = :(a[idx])
	inputsize = :(size(a))
	termtype = :(eltype(a))
	return CodegenHelper(aparams, args, offset_args, term, inputsize, termtype)
end

function codegen_helper(::ArgInfo{-2})
	aparams = [:(f::Functor{1}), :(a1::ContiguousArrOrNum), :(a2::ContiguousArrOrNum)]
	args = [:f, :a1, :a2]
	offset_args = [:f, :(offset_view(a1, ao, m, n)), :(offset_view(a2, ao, m, n))]
	term = :(evaluate(f, getvalue(a1, idx) - getvalue(a2, idx)))
	inputsize = :(mapshape(a1, a2))
	termtype = :(result_type(f, promote_type(eltype(a1), eltype(a2))))
	return CodegenHelper(aparams, args, offset_args, term, inputsize, termtype)
end

function codegen_helper{N}(::ArgInfo{N})
	@assert N >= 1

	aargs = [symbol("a$i") for i = 1 : N]
	aparams = [:(f::Functor{$N}), [:($a::ContiguousArrOrNum) for a in aargs]...]
	args = [:f, aargs...]
	offset_args = [:f, [:(offset_view($a, ao, m, n)) for a in aargs]...]
	term = Expr(:call, :evaluate, :f, [:(getvalue($a, idx)) for a in aargs]...)
	inputsize = Expr(:call, :mapshape, aargs...)
	termtype = Expr(:call, :result_type, :f, [:(eltype($a)) for a in aargs]...)
	return CodegenHelper(aparams, args, offset_args, term, inputsize, termtype)
end

codegen_helper(AN::Int) = codegen_helper(arginfo(AN))

