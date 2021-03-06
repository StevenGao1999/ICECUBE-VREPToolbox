function [ tipPosition ] = ur5GetIKTipPosition( icecube )
%ur5GetIKTipPosition Get UR5's ikTip's position from the V-REP scene
% icecube: the icecube object
% tipPosition: the cartesian position of UR5's ikTip

[res, tipPosition] = icecube.vrep.simxGetObjectPosition(icecube.clientID,icecube.handles.ur5ikTip,-1,icecube.vrep.simx_opmode_blocking);
icecube.vrchk(res);

end

