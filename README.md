# PushInterface.jl

It's a Julia (https://julialang.org) library for Ableton Push 2 (https://github.com/Ableton/push-interface).


### Examples

* Interactive websocket communication with [Bukdu.jl](https://github.com/wookay/Bukdu.jl)
  - [bukdu/websockets.jl](https://github.com/wookay/PushInterface.jl/blob/master/examples/bukdu/websocket.jl)

* Insertion data with [Octo.jl](https://github.com/wookay/Octo.jl)
  - [octo/employee.jl](https://github.com/wookay/PushInterface.jl/blob/master/examples/octo/employee.jl)

* Juno IDE (http://junolab.org/) workspace
  - [juno/workspace.jl](https://github.com/wookay/PushInterface.jl/blob/master/examples/juno/workspace.jl)

* Rotating a Cube in Blender (https://www.blender.org/) with [BlenderPlot.jl](https://github.com/wookay/BlenderPlot.jl)
  - [blenderplot/osc.jl](https://github.com/wookay/PushInterface.jl/blob/master/examples/blenderplot/osc.jl)


## Requirements

You need latest [Julia 0.7 beta](https://julialang.org/downloads/nightlies.html).

`julia>` type `]` key

```julia
(v0.7) pkg> add Cairo#master
(v0.7) pkg> add https://github.com/wookay/PushInterface.jl.git#master
```
