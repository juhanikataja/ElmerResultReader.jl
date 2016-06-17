# ElmerResultReader

Elmer `.result` and `.dat` -file readers for julia.

## Usage

```julia
using ElmerResultReader

res = readelmervars(resfilename)
dat = readelmerdat(datname, NPROC=1, DICT=false)
```

Now `res` is an array containing Elmer variables that are found in the
`resfilename` and `dat` contains data saved with savescalars

## Features and caveats

* Supports ASCII 3 format




[![Build Status](https://travis-ci.org/juhanikataja/ElmerResultReader.jl.svg?branch=master)](https://travis-ci.org/juhanikataja/ElmerResultReader.jl)
