-- Threaded Child Script

-- Attach these scripts to UR5 in V-REP scene "UR5plusRG2_PickAndPlace.ttt"

enableIk=function(enable)
    if enable then
        sim.setObjectMatrix(ikTarget,-1,sim.getObjectMatrix(ikTip,-1))
        for i=1,#jointHandles,1 do
            sim.setJointMode(jointHandles[i],sim.jointmode_ik,1)
        end

        sim.setExplicitHandling(ikGroupHandle,0)
    else
        sim.setExplicitHandling(ikGroupHandle,1)
        for i=1,#jointHandles,1 do
            sim.setJointMode(jointHandles[i],sim.jointmode_force,0)
        end
    end
end

rem_rmlMoveToJointPositions = function(inFloats)   -- rad
    local targetPos = {0,0,0,0,0,0}
    if #inFloats>=6 then
        for i = 1,6,1 do
            targetPos[i] = inFloats[i]
        end
    else
        for i = 1,#inFloats,1 do
            targetPos[i] = inFloats[i]
        end
    end
    if sim.getIntegerSignal('IKEnable') ~= 0 then
        enableIk(false)
        sim.setIntegerSignal('IKEnable', 0)
    end
    if sim.getSimulationState() ~= sim.simulation_advancing_abouttostop then
        local res = sim.rmlMoveToJointPositions(jointHandles,-1,currentVel,currentAccel,maxVel,maxAccel,maxJerk,targetPos,targetVel)
    end
    return res 
end

rem_rmlMoveToJointPositions_pro = function(initialVel, inFloats, finalVel)
    --local initialVel = {0,0,0,0,0,0}
    local targetPos = {0,0,0,0,0,0}
    --local finalVel = {0,0,0,0,0,0}
    if #inFloats>=6 then
        for i = 1,6,1 do
            targetPos[i] = inFloats[i]
        end
    else
        for i = 1,#inFloats,1 do
            targetPos[i] = inFloats[i]
        end
    end
    if sim.getIntegerSignal('IKEnable') ~= 0 then
        enableIk(false)
        sim.setIntegerSignal('IKEnable', 0)
    end
    if sim.getSimulationState() ~= sim.simulation_advancing_abouttostop then
        sim.rmlMoveToJointPositions(jointHandles,-1,initialVel,currentAccel,maxVel,maxAccel,maxJerk,targetPos,finalVel)
    end
end

rem_rmlMoveToPosition = function(inFloats)
    local targetPos = sim.getObjectPosition(ikTip, -1)
    local targetQua = sim.getObjectQuaternion(ikTip, -1)
    if #inFloats>=7 then
        for i = 1,3,1 do
            targetPos[i] = inFloats[i]
        end
        for i = 1,4,1 do
            targetQua[i] = inFloats[i+3]
        end
    else
        print('There should be 7 elements in the desired configuration!')
    end
    if sim.getIntegerSignal('IKEnable') ~= 1 then
        enableIk(true)
        sim.setIntegerSignal('IKEnable', 1)
    end
    if sim.getSimulationState() ~= sim.simulation_advancing_abouttostop then
        local res = sim.rmlMoveToPosition(ikTarget, -1, -1, nil, nil, ikMaxVel, ikMaxAccel, ikMaxJerk, targetPos, targetQua, nil)
    end
    return res
end

function sysCall_threadmain(  )
    sim.setThreadSwitchTiming(100)
    sim.setIntegerSignal('ClientRunning', 0)
    -- Initialize some values:
    jointHandles={-1,-1,-1,-1,-1,-1}
    for i=1,6,1 do
        jointHandles[i]=sim.getObjectHandle('UR5_joint'..i)
    end
    ikGroupHandle=sim.getIkGroupHandle('UR5')
    ikTip=sim.getObjectHandle('UR5_ikTip')
    ikTarget=sim.getObjectHandle('UR5_ikTarget')

    -- Set-up some of the RML vectors:
    vel = 60
    accel = 40
    jerk = 80
    currentVel={0,0,0,0,0,0}
    currentAccel={0,0,0,0,0,0}
    maxVel={vel*math.pi/180,vel*math.pi/180,vel*math.pi/180,vel*math.pi/180,vel*math.pi/180,vel*math.pi/180}
    maxAccel={accel*math.pi/180,accel*math.pi/180,accel*math.pi/180,accel*math.pi/180,accel*math.pi/180,accel*math.pi/180}
    maxJerk={jerk*math.pi/180,jerk*math.pi/180,jerk*math.pi/180,jerk*math.pi/180,jerk*math.pi/180,jerk*math.pi/180}
    targetVel={0,0,0,0,0,0}

    ikMaxVel={0.4,0.4,0.4,1.8}
    ikMaxAccel={0.8,0.8,0.8,0.9}
    ikMaxJerk={0.6,0.6,0.6,0.8}

    initialConfig={0,0,0,0,0,0}
    

    sim.setIntegerSignal('IKEnable', 0)         -- The sign for ik mechanism
    
    -- The ICECUBE Communication Protocol v1.1
    sim.setIntegerSignal('ICECUBE_0', 0)
    for i = 1,7,1 do
        sim.setFloatSignal('ICECUBE_'..i, 0.000000)
    end
    local rmlJoints = {0, 0, 0, 0, 0, 0}
    local rmlPosQua = {0, 0, 0, 0, 0, 0, 0} 

    sim.setIntegerSignal('ClientRunning',1)     -- the sign for client applications
    sim.addStatusbarMessage('The UR5 is ready to move!')

    
    
    while true do
        -- The ICECUBE Communication Protocol v1.1
        local icecube_sign = sim.getIntegerSignal('ICECUBE_0')
        if icecube_sign == 0 then
            -- Nothing to do, pass
            sim.wait(0.2)
        elseif icecube_sign == 1 then
            -- Joint Motion Plan
            --sim.addStatusbarMessage('Joint Motion Planning!')
            for i = 1,6,1 do
                rmlJoints[i] = sim.getFloatSignal('ICECUBE_'..i)
            end
            rem_rmlMoveToJointPositions(rmlJoints)
            sim.wait(0.2)
            sim.setIntegerSignal('ICECUBE_0', 0)
        elseif icecube_sign == 2 then
            -- Cartesian Motion
            --sim.addStatusbarMessage('Cartesian Motion Planning!')
            for i = 1,7,1 do
                rmlPosQua[i] = sim.getFloatSignal('ICECUBE_'..i)
            end
            rem_rmlMoveToPosition(rmlPosQua)
            sim.wait(0.2)
            sim.setIntegerSignal('ICECUBE_0', 0)
        elseif icecube_sign == 3 then
            -- Stop Simulation
            break
        elseif icecube_sign == 4 then
            -- A series of joint motion (at least 3 points)
            -- ICECUBE Communication Protocol v1.1
            sim.setIntegerSignal('ICECUBE_0', 0)
        elseif icecube_sign == 5 then
            -- Prefessional Joint Motion Plan
            -- The starting point
            --sim.addStatusbarMessage('Joint Motion Plan: Starting Point!')
            for i = 1,6,1 do
                rmlJoints[i] = sim.getFloatSignal('ICECUBE_'..i)
            end
            rem_rmlMoveToJointPositions_pro(currentVel,rmlJoints,currentVel)
            sim.setIntegerSignal('ICECUBE_0', 0)
        elseif icecube_sign == 6 then
            -- Professional Joint Motion Plan
            -- The route point
            --sim.addStatusbarMessage('Joint Motion Plan: Route Point!')
            for i = 1,6,1 do
                rmlJoints[i] = sim.getFloatSignal('ICECUBE_'..i)
            end
            rem_rmlMoveToJointPositions_pro(currentVel,rmlJoints,currentVel)
            sim.setIntegerSignal('ICECUBE_0', 0)
        elseif icecube_sign == 7 then
            -- Professional Joint Motion Plan
            -- The ending point
            --sim.addStatusbarMessage('Joint Motion Plan: Ending Point!')
            for i = 1,6,1 do
                rmlJoints[i] = sim.getFloatSignal('ICECUBE_'..i)
            end
            rem_rmlMoveToJointPositions_pro(currentVel,rmlJoints,currentVel)
            sim.setIntegerSignal('ICECUBE_0', 0)
        end
    end

    sim.stopSimulation()
end