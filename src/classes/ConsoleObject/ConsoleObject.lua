--[=[
<1>{ <2>{
    ___type = "static_class<ConsoleObject>",
    __index = <function 1>
  },
  ___type = "static_class<ConsoleObject>",
  __index = <table 2>,
  <metatable> = <table 1>
}
]=]

--- @meta

--- Now just imagine you ran a script through the console. This would be the topmost class in the hierarchy.
--- @class ConsoleObject: userdata
--- @field ___type 'static_class<ConsoleObject>'
--- @field __index fun(self: ConsoleObject, index: string): any
local ConsoleObject = {}
