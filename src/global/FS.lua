--[[
<1>{ <2>{
    ___type = "class<BNGBase_FS_IFileSystem>",
    __gc = <function 1>,
    __index = <function 2>,
    closeDirectory = <function 3>,
    copyFile = <function 4>,
    directoryCreate = <function 5>,
    directoryExists = <function 6>,
    directoryList = <function 7>,
    directoryRemove = <function 8>,
    expandFilename = <function 9>,
    fileExists = <function 10>,
    fileSize = <function 11>,
    findFiles = <function 12>,
    findFilesByPattern = <function 13>,
    findFilesByRootPattern = <function 14>,
    findOverrides = <function 15>,
    getFileRealPath = <function 16>,
    getGamePath = <function 17>,
    getLastError = <function 18>,
    getUserPath = <function 19>,
    hashFile = <function 20>,
    hashFileSHA1 = <function 21>,
    isGamePathCaseSensitive = <function 22>,
    isMounted = <function 23>,
    isPathInCaseSensitiveMount = <function 24>,
    isUserPathCaseSensitive = <function 25>,
    listOverrides = <function 26>,
    mount = <function 27>,
    mountList = <function 28>,
    native2Virtual = <function 29>,
    openDirectory = <function 30>,
    openFile = <function 31>,
    remove = <function 32>,
    removeFile = <function 33>,
    renameFile = <function 34>,
    stat = <function 35>,
    triggerFilesChanged = <function 36>,
    unmount = <function 37>,
    updateDirectoryWatchers = <function 38>,
    virtual2Native = <function 39>
  },
  ___type = "class<BNGBase_FS_IFileSystem>",
  __gc = <function 1>,
  __index = <table 2>,
  <metatable> = <table 1>
}
]]

--- @meta

--- @class BNGBase_FS_IFileSystem: userdata
--- @field ___type 'class<BNGBase_FS_IFileSystem>'
--- @field __gc function
--- @field __index function
--- @field closeDirectory function
--- @field copyFile function
--- @field directoryCreate function
--- @field directoryExists function
--- @field directoryList function
--- @field directoryRemove function
--- @field expandFilename function
--- @field fileExists function
--- @field fileSize function
--- @field findFiles function
--- @field findFilesByPattern function
--- @field findFilesByRootPattern function
--- @field findOverrides function
--- @field getFileRealPath function
--- @field getGamePath function
--- @field getLastError function
--- @field getUserPath function
--- @field hashFile function
--- @field hashFileSHA1 function
--- @field isGamePathCaseSensitive function
--- @field isMounted function
--- @field isPathInCaseSensitiveMount function
--- @field isUserPathCaseSensitive function
--- @field listOverrides function
--- @field mount function
--- @field mountList function
--- @field native2Virtual function
--- @field openDirectory function
--- @field openFile function
--- @field remove function
--- @field removeFile function
--- @field renameFile function
--- @field stat function
--- @field triggerFilesChanged function
--- @field unmount function
--- @field updateDirectoryWatchers function
--- @field virtual2Native function
local BNGBase_FS_IFileSystem = {}

--- @type BNGBase_FS_IFileSystem | userdata
FS = {}
