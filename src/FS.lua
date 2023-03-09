--- @meta
--- @module 'FS'

--- @class FS
FS = {}

--- @param directory string
--- @param pattern string
--- @param depth number
--- @param includeDirectories boolean
--- @param includeHiddenFiles boolean
--- @return string[] files
function FS:findFiles(directory, pattern, depth, includeDirectories, includeHiddenFiles) end

return FS
