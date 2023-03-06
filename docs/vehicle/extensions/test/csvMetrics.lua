-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local enabled = false
local frame = 1
local rowFmt = ''
local csvFile = nil
local csvHandle = nil
local rate = nil

local time = 0

function string:split(delimiter)
  local result = {}
  local from  = 1
  local delim_from, delim_to = string.find(self, delimiter, from)
  while delim_from do
    table.insert(result, string.sub(self, from , delim_from-1 ))
    from  = delim_to + 1
    delim_from, delim_to = string.find(self, delimiter, from)
  end
  table.insert(result, string.sub(self, from))
  return result
end

M.enable = function(path, writeRate)
  csvFile = path
  rate = writeRate or 64

  local header = 'Time,' ..
                 'EnvTemp,' ..
                 'Airflow,' ..
                 'Airspeed,' ..
                 'Driveshaft,' ..
                 'DriveshaftF,' ..
                 'EngineLoad,' ..
                 'ExhaustFlow,' ..
                 'Fuel,' ..
                 'FualCapacity,' ..
                 'FuelVolume,' ..
                 'GearIndex,' ..
                 'Oil,' ..
                 'OilTemp,' ..
                 'RadiatorFanSpin,' ..
                 'RPM,' ..
                 'RPMSpin,' ..
                 'WaterTemp,' ..
                 'WheelSpeed,'

  for k, v in pairs(electrics.values.wheelThermals) do
    header = header .. 'BrakeCoreTemp' .. k .. ','
    header = header .. 'BrakeSurfaceTemp' .. k .. ','
    header = header .. 'BrakeThermalEfficiency' .. k .. ','
  end
  for k, v in pairs(powertrain.getDevicesByType('combustionEngine')) do
    if v.thermals ~= nil then
      header = header .. 'EngineBlockTemp' .. v.name ..','
      header = header .. 'CylinderWallTemp' .. v.name .. ','
      header = header .. 'CoolantTemp' .. v.name .. ','
      header = header .. 'ExhaustTemp' .. v.name .. ','
    end
  end
  header = header:sub(1, header:len() - 1) .. '\n'

  for i, v in ipairs(header:split(',')) do
    rowFmt = rowFmt .. '%f,'
  end
  rowFmt = rowFmt:sub(1, rowFmt:len() - 1) .. '\n'

  local err = nil
  csvHandle, err = io.open(path, 'w')
  if csvHandle == nil then
    log('E', 'csvMetrics', 'Error opening performance report file: ' .. path .. ': ' .. err)
    enabled = false
  else
    log('I', 'csvMetrics', 'Opened vehicle performance report file: ' .. path)
    csvHandle:write(header)
    enabled = true
  end
end

local function writeRow()
  local dataRow = {
    time,
    obj:getEnvTemperature() - 273.15,
    electrics.values.airflowspeed or 0,
    electrics.values.airspeed or 0,
    electrics.values.driveshaft or 0,
    electrics.values.driveshaft_F or 0,
    electrics.values.engineLoad or 0,
    electrics.values.exhaustFlow or 0,
    electrics.values.fuel or 0,
    electrics.values.fuelCapacity or 0,
    electrics.values.fuelVolume or 0,
    electrics.values.gearIndex or 0,
    electrics.values.oil or 0,
    electrics.values.oiltemp or 0,
    electrics.values.radiatorFanSpin or 0,
    electrics.values.rpm or 0,
    electrics.values.rpmspin or 0,
    electrics.values.watertemp or 0,
    electrics.values.wheelspeed or 0
  }
  for k, v in pairs(electrics.values.wheelThermals) do
    table.insert(dataRow, v.brakeCoreTemperature or 0)
    table.insert(dataRow, v.brakeSurfaceTemperature or 0)
    table.insert(dataRow, v.brakeThermalEfficiency or 0)
  end
  for k, v in pairs(powertrain.getDevicesByType('combustionEngine')) do
    print('Values')
    print(v.thermals.engineBlockTemperature)
    print(v.thermals.cylinderWallTemperature)
    print(v.thermals.coolantTemperature)
    print(v.thermals.exhaustTemperature)
    table.insert(dataRow, v.thermals.engineBlockTemperature)
    table.insert(dataRow, v.thermals.cylinderWallTemperature)
    table.insert(dataRow, v.thermals.coolantTemperature)
    table.insert(dataRow, v.thermals.exhaustTemperature)
  end

  local dataRow = string.format(rowFmt, unpack(dataRow))
  csvHandle:write(dataRow)
  csvHandle:flush()
end

M.updateGFX = function(dt)
  if not enabled then
    return
  end

  time  = time + dt
  frame = frame + 1

  if frame % rate == 0 then
    writeRow()
  end
end

M.disable = function()
  log('I', 'csvMetrics', 'Closing csv report file: ' .. csvFile)
  csvHandle:close()
end

return M
