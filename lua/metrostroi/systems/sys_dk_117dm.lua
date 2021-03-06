--------------------------------------------------------------------------------
-- DK-117DM DC engine
--------------------------------------------------------------------------------
-- Copyright (C) 2013-2018 Metrostroi Team & FoxWorks Aerospace s.r.o.
-- Contains proprietary code. See license.txt for additional information.
--------------------------------------------------------------------------------
Metrostroi.DefineSystem("DK_117DM")
function TRAIN_SYSTEM:Initialize()
    -- Speed of train in km/h
    self.Speed = 0

    -- Winding resistance
    self.Rwa = 0.0819 -- Ohms, anchor
    self.Rws = 0.0396 -- Ohms, stator

    -- Voltage generated by engine
    self.E13 = 0.0 -- Volts
    self.E24 = 0.0 -- Volts

    -- Rotation rate
    self.RotationRate = 0.0

    -- Magnetic flux in the engine
    self.MagneticFlux13 = 0.0
    self.MagneticFlux24 = 0.0

    -- Field reduction (how much current goes through stator)
    self.FieldReduction13 = 0.0
    self.FieldReduction24 = 0.0

    -- Moment generated by the engine
    self.Moment13 = 0.0
    self.Moment24 = 0.0
    self.BogeyMoment = 0.0 -- Moment on front and rear bogey is equal

    -- Need many iterations for engine simulation to converge
    self.SubIterations = 16
end

function TRAIN_SYSTEM:Inputs()
    return { "Speed" }
end

function TRAIN_SYSTEM:Outputs()
    return { "BogeyMoment", }
    --"Speed","Rwa","Rws","E13","E24","RotationRate","MagneticFlux13","MagneticFlux24","FieldReduction13","FieldReduction24","Moment13","Moment24","BogeyMoment"}
end

function TRAIN_SYSTEM:TriggerInput(name,value)
    if name == "Speed" then
        self.Speed = value
    end
end

function TRAIN_SYSTEM:Think(dT)
    local Train = self.Train

    -- Get rate of engine rotation
    local currentRotationRate = 3000 * (self.Speed/80)
    self.RotationRate = self.RotationRate + 5.0 * (currentRotationRate - self.RotationRate) * dT

    self.Rws = 0.0396 -- Ohms, stator
    self.Rwa = 0.1215-self.Rws -- Ohms, anchor

    -- Calculate magnetic flux in the engine
    local a = 0.1204
    local b = 1.3075
    local c = 0.3461
    local Is13 = math.abs(Train.Electric.Istator13)
    local Is24 = math.abs(Train.Electric.Istator24)
    local X1 = (Train.Electric.I13 < 0 and 1 or 0)
    local X2 = (Train.Electric.I24 < 0 and 1 or 0)
    --self.MagneticFlux13 = (Is13/255)*math.min(1.0,a+b*math.exp(-c*Is13/74))
    --self.MagneticFlux24 = (Is24/255)*math.min(1.0,a+b*math.exp(-c*Is24/74))
    self.MagneticFlux13 = (Is13/(255+X1*(1-math.min(1,self.RotationRate/1125))*40))*math.min(1.0,a+b*math.exp(-c*Is13/74))
    self.MagneticFlux24 = (Is24/(255+X2*(1-math.min(1,self.RotationRate/1125))*40))*math.min(1.0,a+b*math.exp(-c*Is24/74))
    self.MagneticFlux13 = math.min(8.0,math.max(0.01,self.MagneticFlux13))
    self.MagneticFlux24 = math.min(8.0,math.max(0.01,self.MagneticFlux24))

    -- Calculate voltage generated by engines from magnetic flux
    self.E13 = self.RotationRate * self.MagneticFlux13
    self.E24 = self.RotationRate * self.MagneticFlux24

    self.E13 = math.max(-4000,math.min(4000,self.E13))
    self.E24 = math.max(-4000,math.min(4000,self.E24))

    -- Calculate engine force (moment)
    local b = 3.5539
    local c = 0.0042
    local I13 = math.abs(Train.Electric.I13)
    local I24 = math.abs(Train.Electric.I24)
    local S13 = (Train.Electric.I13 > 0) and 1 or -1
    local S24 = (Train.Electric.I24 > 0) and 1 or -1
    self.Moment13 = S13*(b*I13 + c*(I13^2))*(1/720.0)*self.MagneticFlux13
    self.Moment24 = S24*(b*I24 + c*(I24^2))*(1/720.0)*self.MagneticFlux24 --1/800

    -- Apply moment to bogeys
    if (math.abs(Train.Electric.I13) > 1.0) or (math.abs(Train.Electric.I24) > 1.0) then
        self.BogeyMoment = (self.Moment13 + self.Moment24) / 2
    else
        self.BogeyMoment = 0.0
    end

    -- Calculate reduction in magnetic field
    self.FieldReduction13 = math.abs(100 * Is13 / (I13+1e-9))
    self.FieldReduction24 = math.abs(100 * Is24 / (I24+1e-9))
end
