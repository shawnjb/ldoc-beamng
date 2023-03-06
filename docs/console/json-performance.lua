-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local json = require('json')
local lpack = require('lpack')
local buffer = require('string.buffer')

local reruns = 6 -- how often to reparse the json
local debug = false -- true

local hp = HighPerfTimer()

-- finding files
local filenames = FS:findFiles('/vehicles', '*.jbeam', -1, false, false)
print(' * Finding all ' .. tostring(#filenames) .. ' json files took ' ..  string.format('%0.3f', hp:stopAndReset()) .. 's')

-- reading into memory
local fileContent = {}
local totalSize = 0
for _, filename in pairs(filenames) do
  fileContent[filename] = readFile(filename)
  totalSize = totalSize + string.len(fileContent[filename])
  --print(' * ' ..tostring(filename))
end

local t = hp:stopAndReset()
print(' * Reading into memory took ' .. string.format('%0.3f', t) .. 's. Size: ' .. string.format('%0.3f', (totalSize) /1000/1000 ) .. ' MB. Performance: ' .. string.format('%0.3f', (totalSize / t) /1000/1000 ) .. ' MB/s')

-- parsing
local function test()
  hp:stopAndReset()
  for i= 1, reruns do
    for filename, content in pairs(fileContent) do
      --print(' * ' ..tostring(filename))
      local data = json.decode(content)
    end
  end
  local t = hp:stopAndReset()
  local totalSizeReruns = totalSize * reruns
  print(' * Parsing (' .. tostring(reruns) .. 'x = '.. string.format('%0.3f', totalSizeReruns /1000000 ) .. ' MB) took ' .. string.format('%0.3f', t) .. 's. Performance: ' .. string.format('%0.3f', (totalSizeReruns/1000000) / t  ) .. ' MB/s'..string.format(' in %0.3f msec', t))
end

test()
-- require('jit').off()
-- print(" == JIT off ==")
-- test()

local luaContent = {}
for filename, content in pairs(fileContent) do
  --print(' * ' ..tostring(filename))
  local state, data = pcall(json.decode, content)
  luaContent[filename] = data
end

local lpackContent = {}
local totalPackSize = 0
local function testLpackEncode()
  hp:stopAndReset()
  for i= 1, reruns do
    for filename, content in pairs(luaContent) do
      --print(' * ' ..tostring(filename))
      lpackContent[filename] = lpack.encode(content)
      totalPackSize = totalPackSize + #lpackContent[filename]
    end
  end
  local t = hp:stopAndReset()
  local totalSizeReruns = totalSize * reruns
  print('Total packed size = '..totalPackSize)
  print(' * Parsing (' .. tostring(reruns) .. 'x = '.. string.format('%0.3f', totalSizeReruns /1000000 ) .. ' MB) took ' .. string.format('%0.3f', t) .. 's. Performance: ' .. string.format('%0.3f', (totalSizeReruns/1000000) / t  ) .. ' MB/s'..string.format(' in %0.3f msec', t))
end

print()
print(" == Lpack Encode ==")
testLpackEncode()

local function testLpackDecode()
  hp:stopAndReset()
  for i= 1, reruns do
    for filename, content in pairs(lpackContent) do
      --print(' * ' ..tostring(filename))
      lpack.decode(content)
    end
  end
  local t = hp:stopAndReset()
  local totalSizeReruns = totalPackSize
  print(' * Parsing (' .. tostring(reruns) .. 'x = '.. string.format('%0.3f', totalSizeReruns /1000000 ) .. ' MB) took ' .. string.format('%0.3f', t) .. 's. Performance: ' .. string.format('%0.3f', (totalSizeReruns/1000000) / t  ) .. ' MB/s'..string.format(' in %0.3f msec', t))
end

print(" == Lpack Decode ==")
testLpackDecode()

lpackContent = {}
local totalPackSize = 0
local function testLpackEncodeBin()
  hp:stopAndReset()
  for i= 1, reruns do
    for filename, content in pairs(luaContent) do
      --print(' * ' ..tostring(filename))
      lpackContent[filename] = lpack.encodeBin(content)
      totalPackSize = totalPackSize + #lpackContent[filename]
    end
  end
  local t = hp:stopAndReset()
  local totalSizeReruns = totalSize * reruns
  print('Total packed size = '..totalPackSize)
  print(' * Parsing (' .. tostring(reruns) .. 'x = '.. string.format('%0.3f', totalSizeReruns /1000000 ) .. ' MB) took ' .. string.format('%0.3f', t) .. 's. Performance: ' .. string.format('%0.3f', (totalSizeReruns/1000000) / t  ) .. ' MB/s'..string.format(' in %0.3f msec', t))
end

print()
print(" == Lpack EncodeBin ==")
testLpackEncodeBin()

print(" == Lpack DecodeBin ==")
testLpackDecode()

local strbufContent = {}
local totalPackSize = 0
local function strbufEncode()
  hp:stopAndReset()
  for i= 1, reruns do
    for filename, content in pairs(luaContent) do
      --print(' * ' ..tostring(filename))
      strbufContent[filename] = tostring(buffer.encode(content))
      totalPackSize = totalPackSize + #strbufContent[filename]
    end
  end
  local t = hp:stopAndReset()
  local totalSizeReruns = totalSize * reruns
  print('Total packed size = '..totalPackSize)
  print(' * Parsing (' .. tostring(reruns) .. 'x = '.. string.format('%0.3f', totalSizeReruns /1000000 ) .. ' MB) took ' .. string.format('%0.3f', t) .. 's. Performance: ' .. string.format('%0.3f', (totalSizeReruns/1000000) / t  ) .. ' MB/s'..string.format(' in %0.3f msec', t))
end

print()
print(" == string.buffer Encode ==")
strbufEncode()

local function strbufDecode()
  hp:stopAndReset()
  for i= 1, reruns do
    for filename, content in pairs(strbufContent) do
      --print(' * ' ..tostring(filename))
      buffer.decode(content)
    end
  end
  local t = hp:stopAndReset()
  local totalSizeReruns = totalPackSize
  print(' * Parsing (' .. tostring(reruns) .. 'x = '.. string.format('%0.3f', totalSizeReruns /1000000 ) .. ' MB) took ' .. string.format('%0.3f', t) .. 's. Performance: ' .. string.format('%0.3f', (totalSizeReruns/1000000) / t  ) .. ' MB/s'..string.format(' in %0.3f msec', t))
end

print(" == string.buffer Decode ==")
strbufDecode()
