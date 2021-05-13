local reactorSide = "back"
local fluxOutputSide = "right"
local maxTemp = 8000
local targetTemp = 7500

os.loadAPI("lib/f")


local reactor
local fluxInput
local fluxExtract

--local version = 1.2
local version = "2.1"

local mon, monitor, monX, monY

local reactorInfo


reactor = peripheral.wrap(reactorSide)
fluxOutput = peripheral.wrap(fluxOutputSide)
fluxInput = f.periphSearch("flux_gate")
monitor = f.periphSearch("monitor")


if reactor == null then
    error("No reactor found. Expected on ".. reactorSide .. " side.")
end

if fluxOutput == null then
    error("No output flux gate found. Expected on " .. fluxOutputSide .. " side.")
end

if fluxInput == null then
    error("No input flux gate found. Expected on network.")
end

if monitor == null then
    error("No monitor found. Expected on network.")
end



monX, monY = monitor.getSize()
mon = {}
mon.monitor, mon.X, mon.Y = monitor, monX, monY
print(mon.monitor)
--[[
if fluxOutput.getSignalLowFlow() <= 300000 then
    fluxOutput.setSignalLowFlow(300000)
end

if fluxInput.getSignalLowFlow() <= 100000 then
    fluxInput.setSignalLowFlow(100000)
end
--]]

f.clear(mon)


reactorInfo = reactor.getReactorInfo()

for i,k in pairs(reactorInfo) do
    print(i .. ": " .. tostring(k))
end



for i,k in pairs(reactor) do
    print(i .. ": " .. tostring(k))
end


function draw_vertical(mon, x, y, length, color)
    if length < 0 then
        length = 0
    end
    
    for i=y, length+y, 1 do
        
        f.draw_line(mon, x, i, 1, color)
    end
    

end


function drawReactorInfo(mon, reactorInfo)
    
    infoX, infoY = 4, 4
    --draw fuel conversion
    fuelPercentage = math.floor((reactorInfo.fuelConversion / reactorInfo.maxFuelConversion)*10000)/100
    if fuelPercentage > 75 then
        fuelColor = colors.orange
        if fuelPercentage > 90 then
            fuelColor = colors.red
        end
    else
        fuelColor = colors.green
    end
    f.draw_text(mon, infoX,infoY, ("Fuel left: " .. 100-fuelPercentage .. "%") ,colors.white, colors.black)
    f.progress_bar(mon, infoX, infoY+1, 20, fuelPercentage, 100, fuelColor, colors.gray)
    
    --draw reactor temp
    reactorPercentage = math.floor((reactorInfo.temperature / maxTemp)*10000)/100
    if reactorInfo.temperature > (targetTemp + 1) then
        reactorColor = colors.orange
        if reactorInfo.temperature>maxTemp then
            reactorColor = colors.red
        end
    else
        reactorColor = colors.green
    end
    f.draw_text(mon, infoX, infoY+3, ("Temperature: "  .. math.floor(reactorInfo.temperature) .. "°C"), colors.white, colors.black)
    f.progress_bar(mon, infoX, infoY+4, 20, reactorPercentage, 100, reactorColor, colors.gray)
    
    --draw containment field
    fieldPercentage = math.ceil(reactorInfo.fieldStrength / reactorInfo.maxFieldStrength * 10000)*.01
    if fieldPercentage > 55 or fieldPercentage < 50 then  
        fieldColor = colors.orange
        if fieldPercentage < 40 then
            fieldColor = colors.red
        end  
    else
        fieldColor = colors.green
    end
    
    f.draw_text(mon, infoX, infoY+6, ("Field power: " .. fieldPercentage .. "% "), colors.white, colors.black)
    f.progress_bar(mon, infoX, infoY + 7, 20, fieldPercentage, 100, fieldColor, colors.gray)
 
    
    
end 

function drawOutlines(mon)


    draw_vertical(mon, 25, 2, 12, colors.gray)
    f.draw_line(mon, 2, 2, 47, colors.gray)
    f.draw_text(mon, 4, 2, " Info ", colors.white, colors.black)
    f.draw_text(mon, 27, 2, " Log ", colors.white, colors.black)
    
    f.draw_line(mon, 3, 15, 46, colors.gray)
    draw_vertical(mon, 2, 2, 23, colors.gray)
    draw_vertical(mon, 49, 2, 23, colors.gray)
    f.draw_line(mon, 3, 25, 46, colors.gray)
    draw_vertical(mon, 27, 16, 8, colors.gray)
    
    f.draw_text(mon, 4, 15, " Status ", colors.white, colors.black)
    f.draw_text(mon, 29, 15, " IO ", colors.white, colors.black)
    
    f.draw_line(mon, 1, 14, 50, colors.black)
    f.draw_line(mon, 2, 13, 48, colors.gray)
    
    f.draw_text(mon, 39, 25, " ver "..version.." ", colors.gray, colors.black)
    
end


local IOX, IOY = 30, 17
function drawReactorIO(mon, reactorInfo)
    if fluxOutput.getSignalLowFlow() > 999999 then
        f.draw_text(mon, IOX, IOY, ("Out: " .. fluxOutput.getSignalLowFlow() .. " rf/t"), colors.green,colors.black)
    else
        f.draw_text(mon, IOX, IOY, ("Out:  " .. fluxOutput.getSignalLowFlow() .. " rf/t"), colors.green,colors.black)
    end
    f.draw_text(mon, IOX, IOY+2, ("In:   " .. fluxInput.getFlow() .. " rf/t"), colors.red, colors.black)
    
    netGain = fluxOutput.getSignalLowFlow() - fluxInput.getSignalLowFlow()
    if netGain > 0 then
        gainColor = colors.green
    else
        gainColor = colors.red
    end
    
    f.draw_line(mon, IOX-1, IOY+4, 19, gainColor)
    f.draw_line(mon, IOX-1, IOY+5, 19, gainColor)
    if netGain > 999999 or netGain < -999999 then 
        f.draw_text(mon, IOX-1, IOY+5, (" Gain:" .. (fluxOutput.getSignalLowFlow()-fluxInput.getSignalLowFlow()) .. " rf/t"), colors.white, gainColor)
    else 
        f.draw_text(mon, IOX-1, IOY+5, (" Gain: " .. (fluxOutput.getSignalLowFlow()-fluxInput.getSignalLowFlow()) .. " rf/t"), colors.white, gainColor)
    end
    
    f.draw_line(mon, IOX-1, IOY+6, 19, gainColor)
    
end





buttonX, buttonY = 5, 22

function drawButtons(mon)
    
    
    buttons = {}
    buttons.shutdownX, buttons.shutdownY = buttonX, buttonY
    buttons.startupX, buttons.startupY = buttonX+7, buttonY
    buttons.clearlogX, buttons.clearlogY = buttonX+14, buttonY

    f.draw_text(mon, buttons.shutdownX, buttons.shutdownY, " Shut ", colors.white, colors.gray)
    f.draw_text(mon, buttons.shutdownX, buttons.shutdownY+1, " Down ", colors.white, colors.gray)
    
    

    
    f.draw_text(mon, buttons.startupX, buttons.startupY, "Start ", colors.white, colors.gray)
    f.draw_text(mon, buttons.startupX, buttons.startupY+1, "  Up  ", colors.white, colors.gray)
    
    f.draw_text(mon, buttons.clearlogX, buttons.clearlogY, "Clear " , colors.white, colors.gray)
    f.draw_text(mon, buttons.clearlogX, buttons.clearlogY+1, " Log  ", colors.white, colors.gray)
    
end

function drawReactorStatus(mon)
    drawButtons(mon)

        --draw reactor status
    if reactorInfo.status == "running" then
        statusColor = colors.green
        statusText = "running"
    elseif reactorInfo.status == "warming_up" then
        statusColor = colors.blue
        statusText = "warming up"
    elseif reactorInfo.status == "stopping" then
        statusColor = colors.purple
        statusText = "stopping"
    elseif reactorInfo.status == "cooling" then
        statusColor = colors.orange
        statusText = "cooling"
    elseif reactorInfo.status == "cold" then
        statusColor = colors.gray
        statusText = "offline"
    else
        statusColor = colors.gray
    end
    
    statusX, statusY= 6, 17
    
    f.draw_text(mon, statusX, statusY, ("Reactor is "), colors.white, colors.black)
    f.draw_text(mon, statusX + 11, statusY, statusText, statusColor, colors.black)
    
    f.draw_text(mon, statusX, statusY+2, ("Fuel rate: " .. reactorInfo.fuelConversionRate .. "nb/t"), colors.white, colors.black)
    
end


local conX, conY = 21, 8
local conXoffset, conYoffset = 27, 3
function drawConsole(mon)
    --[[for i=1 + conYoffset, conY+conYoffset, 1 do
        f.draw_line(mon, conXoffset, i, conX, colors.black)
    end--]]
    
    printConsole(mon)
end

local consoleLog = {}
function log(toLog)

    if string.len(toLog)>42 then
        log("String too long")
        log(toLog:sub(1, 42))
        return
    end
    if string.len(toLog)>21 then
        log(toLog:sub(1,21))
        if toLog:sub(22, 22) == " " then
            log(toLog:sub(23,string.len(toLog)))
        else
            log(toLog:sub(22,string.len(toLog)))
        end
        return
    end
    for i=1, conY, 1 do
        if consoleLog[i] == nil then
            consoleLog[i] = toLog
            return
        end
    end
    
    for i=2, conY, 1 do
        consoleLog[i-1] = consoleLog[i]
    end
    consoleLog[conY] = toLog  
end

function logTime(toLog)
    time = os.date("*t")
    log("["..(("%02d:%02d:%02d"):format(time.hour, time.min, time.sec)).."]")
    log(toLog)
    
end

function clearConsole()
    consoleLog = {}
    for i=1 + conYoffset, conY+conYoffset, 1 do
        f.draw_line(mon, conXoffset, i, conX, colors.black)
    end
end

function printConsole(mon)
    for i=1+conYoffset, conY+conYoffset, 1 do
        f.draw_text(mon, conXoffset, i, consoleLog[i-conYoffset], colors.white, colors.black)
    end
end


lastStatus = nil
local weakening
local lastStrength
local strengthTolerance = 0


function manageInputPower(reactorInfo)
    fieldStrength = math.ceil(reactorInfo.fieldStrength / reactorInfo.maxFieldStrength * 10000)*.01
    drainRate = reactorInfo.fieldDrainRate
    
    if lastStrength == null then
       lastStrength = fieldStrength
    end
    
    if (lastStrength - fieldStrength) + strengthTolerance > 0 then
       weakening = true
    else 
       weakening = false
    end
    
    --logTime(drainRate+fluxInput.getSignalLowFlow())
    fluxInput.setSignalLowFlow(drainRate*2)
    --if fieldStrength < 50 and weakening then
    --    logTime("Increasing input")
    --    fluxInput.setSignalLowFlow(drainRate*1.2)
    --end    

    --if fieldStrength > 55 and not weakening then
    --   logTime("Decreasing input")
    --   fluxInput.setSignalLowFlow(drainRate*0.9)   
    --end
     
    lastStrength = fieldStrength
end


local cooling 

local tempTolerance = 3
local emergencyDecrease = false





local minTemp = 2000

function manageOutputPower(reactorInfo)
    
    temp = reactorInfo.temperature
    genRate = reactorInfo.generationRate

    --logTime(""..reactorInfo.status .. " " .. reactorInfo.generationRate)
    if reactorInfo.status ~= "running" or lastStatus == "warming_up" then
        if reactorInfo.status == "stopping" then
            fluxOutput.setSignalLowFlow(reactorInfo.generationRate)
            return
        end
        --logTime("Initial power: " .. reactorInfo.generationRate*25)
        fluxOutput.setSignalLowFlow(reactorInfo.generationRate*25)
        return
    end
    

    if genRate == 0 then
        fluxOutput.setSignalLowFlow(1000)
        return
    end
    
    tempDif = math.floor((targetTemp+1) - temp)
    
    --logTime(changeRate .. ", " .. expectedTemp)
    

    if temp <targetTemp+0.5 then
        fluxOutput.setSignalLowFlow(genRate + tempDif*(genRate/10000))
    else
        if genRate < fluxOutput.getSignalLowFlow() then
            fluxOutput.setSignalLowFlow(genRate)
        end
    end


    --logTime(tempDif)
end


    
function manageFuelEmpty(reactorInfo)
    usedFuelPercent = math.floor((reactorInfo.fuelConversion / reactorInfo.maxFuelConversion)*100)
    if usedFuelPercent > 90 and reactorInfo.status == "running" then
        reactor.stopReactor()
        print("Stopping, fuel almost depleted")
    end
end

function manageWarmup(reactorInfo)
    if math.floor(reactorInfo.temperature) >= 2000 then
        reactor.activateReactor()
        fluxInput.setSignalLowFlow(reactorInfo.fieldDrainRate)
        return
    end
    fluxInput.setSignalLowFlow(1000000)
    
end            
            
function buttons()
    while true do
        sleep(0)
        
        event, side, xPos, yPos = os.pullEvent("monitor_touch")

        if yPos >= 22 and yPos <= 23 then
            reactorStatus = reactor.getReactorInfo().status
            if xPos >=4 and xPos <= 10 then
                
                if reactorStatus == "running" then
                    reactor.stopReactor()
                    logTime("Stopping reactor.")
                    lastTemp = 0
                end
            end
            
            if xPos >=12 and xPos <= 18 then
                if reactorStatus ~= "running" then
                    if reactorStatus == "cold" or reactorStatus == "cooling" then
                        reactor.chargeReactor()
                        logTime("Charging reactor")
                    else
                        
                            reactor.activateReactor()
                            logTime("Starting reactor.")
                        
                    end
                end
            end
            
            if xPos >=20 and xPos <= 26 then
                
                clearConsole()
            end
        end
    end
end


function updateGUI()
                                        
    while true do
        f.clear(mon)
        reactorInfo = reactor.getReactorInfo()
        drawOutlines(mon)
        drawReactorInfo(mon, reactorInfo)
        drawReactorIO(mon, reactorInfo)
        drawReactorStatus(mon, reactorInfo)
        drawConsole(mon)
        
        
        sleep(0.1)
    
        end
    end

function updateIO()
    while true do
        reactorInfo = reactor.getReactorInfo()
        manageOutputPower(reactorInfo)
        if reactorInfo.status == "running" then
            manageFuelEmpty(reactorInfo)
        end
        
        if reactorInfo.status == "warming_up" then 
            manageWarmup(reactorInfo)
        end
        
        --log(reactorInfo.status)
        if reactorInfo.status ~= "cooling" and reactorInfo.status ~= "warming_up" then
            manageInputPower(reactorInfo)
        end
        
        lastStatus = reactorInfo.status
        
        sleep(0.1)
    end
end
parallel.waitForAny(buttons, updateGUI, updateIO)
