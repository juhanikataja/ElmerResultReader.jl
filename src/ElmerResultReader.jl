module ElmerResultReader

export elmervar, readelmervars, readelmerdat, readlinearsystem

type elmervar
  perm::Array{Int64,2}
  permsize::Array{Int64,1}
  values::Array{Float64,2}
  name
end

function readmatch(file::IOStream, matcher; error_msg="Invalid parse")
  if (!(matcher(readline(file))))
    close(file)
    throw(ParseError(error_msg))
  end
end

function readmatch(data::AbstractString, matcher; error_msg="Invalid parse")
  if (!(matcher(data)))
    throw(ParseError(error_msg))
  end
end

function readnlines(data::IOStream, n::Integer)
  outbuf = IOBuffer()
  #=print("reading $(n) lines\n")=#
  for i = 1:n
    line = readline(data)
    write(outbuf, line)
  end
  #=print("ok\n")=#
  return outbuf
end

@doc """
function readelmervars(filename; verbose=1)

Populates elmervar array from results given in ```filename```.
Works only with 1 timestep currently.
""" ->
function readelmervars(filename; verbose=1)
  verbose > 1 ? print("Reading variables from $(filename)\n") : Union{}
  totaldofmatch(x) = x[1:12] == " Total DOFs:"

  charmatch(x,y) = x[1] == y
  commentmatch(x) = charmatch(x,'!')

  ms_t1 = open(filename)
  readmatch(ms_t1, x -> x == " ASCII 3\n")
  readmatch(ms_t1, commentmatch)
  readmatch(ms_t1, x-> x == " Degrees of freedom: \n")

  # read dof table
  line = readline(ms_t1)
  dofdata = []
  while(!totaldofmatch(line))
    readmatch(line, x->ismatch(r".+:.+:", x), error_msg= "Couldn't get dof line")
    dofline = readdlm(IOBuffer(line), ':', ASCIIString)
    dofs = readdlm(IOBuffer(rstrip(dofline[2])), Int64)
    push!(dofdata, [rstrip(dofline[1]) dofs lstrip(dofline[3])])
    line = readline(ms_t1)
  end

  nvars = parse(Int64, match(r".+:\s*(\d*)", line).captures[1])
  line = readline(ms_t1)

  readmatch(line, x -> " Number Of Nodes" == x[1:16])
  nnodes = parse(Int64, match(r".+:\s*(\d*)", line).captures[1])


  t_elmervars = []

  while (true)
    try
      line = readline(ms_t1)
      readmatch(line, x -> "Time:" == x[1:5])
    catch readmatch_error
      if isa(readmatch_error, ParseError) 
        print(readmatch_error.msg)
        break
      else
        if isa(readmatch_error, BoundsError)
          verbose > 2 ? print("Did not find next timestep, exiting\n") : Union{}
          break
        end
      end
    end
    timestep_n = parse(Int64, match(r"^Time:\s*(\d+)\s*(\d+)\s*", line).captures[1])
    verbose>0 ? print("Reading timestep $(timestep_n)") : Union{}

    elmervars = []
    perm = []
    prev_ndof = 0
    for dof in dofdata
      line = readline(ms_t1)
      readmatch(line, x -> ismatch(Regex(dof[1]), line), error_msg="Error: $(line)")
      line = readline(ms_t1)
      readmatch(line, x-> x[1:5] == "Perm:")
      if (!ismatch(r"use previous", line))
        prev_ndof = parse(Int64, match(r".+:\s*\d+\s+(\d+)",line).captures[1])
        dof[2] = prev_ndof
        lines = readnlines(ms_t1, dof[2])
        seekstart(lines)
        perm = readdlm(lines, Int64)
      else
        dof[2] = prev_ndof
      end
      lines = readnlines(ms_t1, dof[2])
      seekstart(lines)
      vals = readdlm(lines, Float64)
      push!(elmervars, elmervar(perm, dof[2:4], vals, dof[1]))
      verbose > 0 ? print(".") : Union{}
    end

    push!(t_elmervars, elmervars)
    verbose > 0 ? print(" Read $(length(elmervars)) variables.\n") : print(".\n")
  end

  return t_elmervars

end

@doc """
function readelmerdat(name, NPROC=1, DICT=false)
Reads .dat file generated with savescalars
""" ->
function readelmerdat(name, NPROC=1, DICT=false)
  datas = Array[]
  if NPROC > 1
    for N = 1:NPROC
      push!(datas, readdlm("$name.$(N-1)"))
    end
  else
    push!(datas, readdlm(name))
  end
  desc = open(readlines, "$name.names")[4:end]
  desc = map(strip, desc)
  if DICT
    datasum = sum(datas)
    datadict = Dict{ASCIIString, Array{Float64,1}}()
    k = 1
    for s in desc
      datadict[s] = datasum[:,k]
      k = k + 1
    end
    return datasum, desc, datadict
  end
  return sum(datas), desc
end



@doc """
function readlinearsystem(prefix; suffix="")

Loads elmer linear system that is saved with SaveLinearSystem.

* Output: A::SparseMatrixCSC{Float64, Int64}, b::Array{Float64,1}
* Input: read data from <prefix>_a.dat and <prefix>_b.dat
""" ->
function readlinearsystem(prefix; suffix="")
  ri = x -> round(Int64, x)
  Alist = readdlm(string(prefix, "_a.dat", suffix))
  blist = readdlm(string(prefix, "_b.dat", suffix))
  A = sparse(ri(Alist[:,1]), ri(Alist[:,2]), Alist[:,3])
  b = blist[:,2]
  return A,b
end

end # module ElmerResultReader
