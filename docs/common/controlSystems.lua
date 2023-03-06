--- @meta

local min = math.min
local max = math.max

--- PID controller with parallel form of the derivative term
--- @class PIDParallel
local PIDParallel = {}
PIDParallel.__index = PIDParallel

--- This PID uses derivative calculation based on the process variable rather than the error to avoid spikes when changing the setpoint
---
--- ```lua
--- local myPID = newPIDParallel(1, 0.5, 0.1, 0, 1)
--- local control = myPID:get(processVariable, setPoint, dt)
--- ```
--- @param kP number proportional gain
--- @param kI number integral gain
--- @param kD number derivative gain
--- @param minOutput number minimum output value
--- @param maxOutput number maximum output value
--- @param integralInCoef number coefficient for the integral term when the error is negative
--- @param integralOutCoef number coefficient for the integral term when the error is positive
--- @param minIntegral number minimum integral value
--- @param maxIntegral number maximum integral value
function newPIDParallel(kP, kI, kD, minOutput, maxOutput, integralInCoef, integralOutCoef, minIntegral, maxIntegral)
	local data = {
		kP = kP,
		kI = kI,
		kD = kD,
		integral = 0,
		integralInCoef = integralInCoef or 1,
		integralOutCoef = integralOutCoef or 1,
		lastProcessVariable = 0,
		minOutput = minOutput or -math.huge,
		maxOutput = maxOutput or math.huge,
	}
	data.maxIntegral = maxIntegral or data.maxOutput / kI
	data.minIntegral = minIntegral or -data.maxIntegral
	setmetatable(data, PIDParallel)
	return data
end

--- Set the PID parameters
--- @param kP number proportional gain
--- @param kI number integral gain
--- @param kD number derivative gain
--- @param minOutput number minimum output value
--- @param maxOutput number maximum output value
--- @param integralInCoef number coefficient for the integral term when the error is negative
--- @param integralOutCoef number coefficient for the integral term when the error is positive
--- @param minIntegral number minimum integral value
--- @param maxIntegral number maximum integral value
function PIDParallel:setConfig(kP, kI, kD, minOutput, maxOutput, integralInCoef, integralOutCoef, minIntegral,
							   maxIntegral)
	self.kP = kP or self.kP
	self.kI = kI or self.kI
	self.kD = kD or self.kD
	self.integralInCoef = integralInCoef or self.integralInCoef
	self.integralOutCoef = integralOutCoef or self.integralOutCoef
	self.minOutput = minOutput or self.minOutput
	self.maxOutput = maxOutput or self.maxOutput
	self.maxIntegral = maxIntegral or self.maxOutput / kI
	self.minIntegral = minIntegral or -self.maxIntegral
end

--- Get the control output
--- @param processVariable number current process variable
--- @param setPoint number setpoint
--- @param dt number time since last call
function PIDParallel:get(processVariable, setPoint, dt)
	local error = setPoint - processVariable
	local integral = self.integral
	integral = min(
		max(integral + error * (error > 0 and self.integralOutCoef or self.integralInCoef) * dt, self.minIntegral),
		self.maxIntegral)
	local output = self.kP * error + self.kI * integral + self.kD * (self.lastProcessVariable - processVariable) / dt
	self.integral = integral
	self.lastProcessVariable = processVariable
	return min(max(output, self.minOutput), self.maxOutput), error
end

--- Reset the PID controller
function PIDParallel:reset()
	self.integral = 0
	self.lastProcessVariable = 0
end

--- Print the PID parameters
function PIDParallel:dump()
	print(string.format("PID Parallel parameters:\n" ..
		"  Proportional gain (kP): %.2f\n" ..
		"  Integral gain (kI): %.2f\n" ..
		"  Derivative gain (kD): %.2f\n" ..
		"  Output limits: [%.2f, %.2f]\n" ..
		"  Integral limits: [%.2f, %.2f]\n",
		self.kP,
		self.kI,
		self.kD,
		self.minOutput,
		self.maxOutput,
		self.minIntegral,
		self.maxIntegral))
end

--- PID controller with standard form of the derivative term
--- @class PIDStandard
local PIDStandard = {}
PIDStandard.__index = PIDStandard

--Usage:
--local myPID = newPIDStandard(1, 0.5, 0.1, 0, 1)
--local control = myPID:get(processVariable, setPoint, dt)

--- This PID uses derivative calculation based on the process variable rather than the error to avoid spikes when changing the setpoint
---
--- ```lua
--- local myPID = newPIDStandard(1, 0.5, 0.1, 0, 1)
--- local control = myPID:get(processVariable, setPoint, dt)
--- ```
--- @param kP number the proportional gain coefficient
--- @param tI number the integral time coefficient (set to 0 to disable)
--- @param tD number the derivative time coefficient (set to 0 to disable)
--- @param minOutput number the minimum output value (defaults to negative infinity)
--- @param maxOutput number the maximum output value (defaults to positive infinity)
--- @param integralInCoef number the coefficient for the integral term when the error is negative (defaults to 1)
--- @param integralOutCoef number the coefficient for the integral term when the error is positive (defaults to 1)
--- @param minIntegral number the minimum integral value (defaults to the negative of maxIntegral)
--- @param maxIntegral number the maximum integral value (defaults to the same value as maxOutput)
--- @return table data A new instance of the `PIDStandard` class.
function newPIDStandard(kP, tI, tD, minOutput, maxOutput, integralInCoef, integralOutCoef, minIntegral, maxIntegral)
	local data = {
		kP = kP,
		tICoef = tI > 0 and 1 / tI or 0, --integral time - try to eliminate past errors within this time, pre-calculate the 1 / tI for optimization purposes
		tD = tD,                   -- derivative time - try to predict error this time in the future
		integral = 0,
		integralInCoef = integralInCoef or 1,
		integralOutCoef = integralOutCoef or 1,
		lastProcessVariable = 0,
		minOutput = minOutput or -math.huge,
		maxOutput = maxOutput or math.huge,
	}
	data.maxIntegral = maxIntegral or data.maxOutput
	data.minIntegral = minIntegral or -data.maxIntegral
	setmetatable(data, PIDStandard)
	return data
end

--- Updates the configuration of the PID controller with the given parameters.
--- @param kP number the proportional gain coefficient
--- @param tI number the integral time coefficient
--- @param tD number the derivative time coefficient
--- @param minOutput number the minimum output value
--- @param maxOutput number the maximum output value
--- @param integralInCoef number the coefficient for the integral term when the error is negative
--- @param integralOutCoef number the coefficient for the integral term when the error is positive
--- @param minIntegral number the minimum integral value
--- @param maxIntegral number the maximum integral value
function PIDStandard:setConfig(kP, tI, tD, minOutput, maxOutput, integralInCoef, integralOutCoef, minIntegral, maxIntegral)
	self.kP = kP or self.kP
	self.tICoef = (tI and tI > 0) and 1 / tI or self.tICoef
	self.tD = tD or self.tD
	self.integralInCoef = integralInCoef or self.integralInCoef
	self.integralOutCoef = integralOutCoef or self.integralOutCoef
	self.minOutput = minOutput or self.minOutput
	self.maxOutput = maxOutput or self.maxOutput
	self.maxIntegral = maxIntegral or self.maxOutput
	self.minIntegral = minIntegral or -self.maxIntegral
end

--- Calculates the control value for the given process variable and setpoint.
--- @param processVariable number The current process variable.
--- @param setPoint number The desired setpoint.
--- @param dt number The time interval since the last call to this function.
--- @return number controlValue, number error
function PIDStandard:get(processVariable, setPoint, dt)
	local error = setPoint - processVariable
	local integral = self.integral
	integral = min(
		max(integral + error * (error > 0 and self.integralOutCoef or self.integralInCoef) * dt, self.minIntegral),
		self.maxIntegral)
	local output = self.kP *
		(error + self.tICoef * integral + self.tD * (self.lastProcessVariable - processVariable) / dt)
	self.integral = integral

	self.lastProcessVariable = processVariable

	return min(max(output, self.minOutput), self.maxOutput),
		error --return control value and error, error can be used to check if the PID reached a somewhat steady state
end

--- Reset the PID controller
function PIDStandard:reset()
	self.integral = 0
	self.lastProcessVariable = 0
end
