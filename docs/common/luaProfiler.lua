--- @meta

--- The `C` class is used for measuring the running time and memory usage of sections of code.
--- @class C
--- @field title string The title of the profiler instance.
local C = {}
C.__index = C

--- Initializes a new instance of the `C` class with the specified title.
--- @param title string The title of the profiler instance.
function C:init(title) end

--- Call once after each section of code whose running time you want to profile.
--- @param section string The name of the section to be profiled.
function C:add(section) end

--- Formats a number with a given number of decimal places and padding.
--- @param value number The number to be formatted.
--- @param decimals number The number of decimal places.
--- @param pad number The number of digits to pad the number with.
--- @param decimalSeparator string The decimal separator to be used.
--- @return string number The formatted number.
function format(value, decimals, pad, decimalSeparator) end

--- Computes statistics for a given result, including the average, relative delta, and unstable relative difference.
--- @param result table The result table.
--- @param slow number The slowest time.
--- @param fast number The fastest time.
--- @param value number The current time.
--- @param dt number The time difference between this computation and the last one.
function computeStats(result, slow, fast, value, dt) end

--- Needs to be used once per independent-function* that you want to profile. (*) which doesn't share any common caller ancestor with a function that already used start().
function C:start() end

--- Finishes profiling the current section.
--- @param compute boolean Set to `false` to silence all logs.
--- @param dt number The time difference between this computation and the last one.
function C:finish(compute, dt) end

--- Creates a new instance of the `C` class.
--- @vararg string
function LuaProfiler(...)
	local o = {}
	setmetatable(o, C)
	o:init(...)
	return o
end
