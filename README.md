# ElmerResultReader

Elmer ```.result``` -file reader for julia.

## Usage

julia```
using ElmerResultReader

res = readelmervars(filename)
```

Now julia```res``` is an array containing Elmer variables that are found in the
julia```filename```.

## Features and caveats

* Supports ASCII 3 format
* One timestep is only supported



[![Build Status](https://travis-ci.org/juhanikataja/ElmerResultReader.jl.svg?branch=master)](https://travis-ci.org/juhanikataja/ElmerResultReader.jl)
