--- @meta
--- @module 'ZipArchive'

--- This function creates a new ZIP archive, adds files to it, extracts them, and prints their hashes.
function testZIP() end

--- @class zip
local zip = {}

--- @alias mode
--- | 'r'
--- | 'w'
--- | 'a'
--- | 'r+'
--- | 'w+'
--- | 'a+'

--- Opens an archive from a file. Returns a zip object on success, nil on failure.
--- @param pathSource string The path to the archive to open.
--- @param mode mode The mode to open the archive in.
function zip:openArchiveName(pathSource, mode) end

--- Adds a new entry to the archive.
--- @param path string The path to the file to add to the archive.
--- @param pathInZip string The path to the file in the archive.
--- @param overrideFile boolean Whether to override the file if it already exists.
function zip:addFile(path, pathInZip, overrideFile) end

--- Returns a list of files that are in the archive.
--- @return string[] files
function zip:getFileList() end

--- Returns the given file's entry hash from it's ID.
--- @param id number The ID of the file.
--- @return string hash
function zip:getFileEntryHashByIdx(id) end

--- @return zip
function ZipArchive() end

return ZipArchive
