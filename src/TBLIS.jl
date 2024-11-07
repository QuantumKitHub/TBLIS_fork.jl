module TBLIS

# bare bindings in separate module
include("LibTBLIS.jl")
using .LibTBLIS

# Constructors
# ------------
@doc """
    TBLIS.scalar(s::Number)

Initializes a tblis scalar from a number.
""" scalar

@doc """
    TBLIS.tensor(A::StridedArray{T<:BlasFloat}, [scalar::Number, szA::Vector{Int}, strA::Vector{Int})

Initializes a tblis tensor from an array that should be strided and admit a pointer to its
data. This operation is deemed unsafe, in the sense that the user is responsible for
ensuring that the reference to the array and the sizes and strides stays alive during the
lifetime of the tensor.
""" tensor

for (T, tblis_init_scalar, tblis_init_tensor, tblis_init_tensor_scaled) in
    ((:Float32, :tblis_init_scalar_s, :tblis_init_tensor_s, :tblis_init_tensor_scaled_s),
     (:Float64, :tblis_init_scalar_d, :tblis_init_tensor_d, :tblis_init_tensor_scaled_d),
     (:ComplexF32, :tblis_init_scalar_c, :tblis_init_tensor_c, :tblis_init_tensor_scaled_c),
     (:ComplexF64, :tblis_init_scalar_z, :tblis_init_tensor_z, :tblis_init_tensor_scaled_z))
    init_scalar = GlobalRef(LibTBLIS, tblis_init_scalar)
    init_tensor = GlobalRef(LibTBLIS, tblis_init_tensor)
    init_tensor_scaled = GlobalRef(LibTBLIS, tblis_init_tensor_scaled)
    @eval begin
        function scalar(s::$T)
            t = Ref{LibTBLIS.tblis_scalar}()
            $init_scalar(t, s)
            return t[]
        end
        function tensor(A::StridedArray{$T,N},
                        s::Number=one(T),
                        szA::Vector{LibTBLIS.len_type}=collect(LibTBLIS.len_type, size(A)),
                        strA::Vector{LibTBLIS.stride_type}=collect(LibTBLIS.stride_type,
                                                                   strides(A))) where {N}
            t = Ref{LibTBLIS.tblis_tensor}()
            if isone(s)
                $init_tensor(t, N, pointer(szA), pointer(A), pointer(strA))
            else
                $init_tensor_scaled(t, $T(s), N, pointer(szA), pointer(A), pointer(strA))
            end
            return t[]
        end
    end
end

# Operations
# ----------
"""
    TBLIS.tensor_add(A::tblis_tensor, idxA::String, B::tblis_tensor, idxB::String)

Tensor operation of the form ``B... := α A... + β B...``.
"""
function tensor_add(A::tblis_tensor, idxA::AbstractString,
                    B::tblis_tensor, idxB::AbstractString)
    return LibTBLIS.tblis_tensor_add(C_NULL, C_NULL, Ref(A), idxA, Ref(B), idxB)
end

"""
    TBLIS.tensor_mult(A::tblis_tensor, idx::String, B::tblis_tensor, idxB::String, C::tblis_tensor, idxC::String)

Tensor operation of the form ``C... := α A... * B... + β C...``.
"""
function tensor_mult(A::tblis_tensor, idxA::AbstractString,
                     B::tblis_tensor, idxB::AbstractString,
                     C::tblis_tensor, idxC::AbstractString)
    return LibTBLIS.tblis_tensor_mult(C_NULL, C_NULL, Ref(A), idxA, Ref(B), idxB, Ref(C),
                                      idxC)
end

"""
    TBLIS.tensor_dot()

Tensor operation of the form ``C := α A... * B...``
"""
function tensor_dot(A::tblis_tensor, idxA::AbstractString,
                    B::tblis_tensor, idxB::AbstractString,
                    C::tblis_scalar)
    return LibTBLIS.tblis_tensor_dot(C_NULL, C_NULL, Ref(A), idxA, Ref(B), idxB, Ref(C))
end

# Utility
# -------
"""
    TBLIS.get_num_threads()

Get the current number of threads the TBLIS library is using.
"""
get_num_threads() = convert(Int, LibTBLIS.tblis_get_num_threads())

"""
    TBLIS.set_num_threads(n::Int)

Set the number of threads the TBLIS library should use equal to `n`.
"""
set_num_threads(n::Integer) = LibTBLIS.tblis_set_num_threads(convert(Cuint, n))

end
