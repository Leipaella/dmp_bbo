% Copyright 2006-2013 Dr. Marc Andreas Freese. All rights reserved.
% marc@coppeliarobotics.com
% www.coppeliarobotics.com
%
% -------------------------------------------------------------------
% This file is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
%
% You are free to use/modify/distribute this file for whatever purpose!
% -------------------------------------------------------------------
%
% This file was automatically created for V-REP release V3.0.2 on March 14th 2013

% Make sure to have the server side running in V-REP!
% Start the server from a child script with following command:
% simExtRemoteApiStart(19999) -- starts a remote API server service on port 19999

function simpleTest()
disp('Program started');
vrep=remApi('remoteApi','extApi.h');
if (vrep.simxStart('127.0.0.1',19999,true,true,5000)>-1)
  disp('Connected to remote API server');
  [res,objs]=vrep.simxGetObjects(vrep.sim_handle_all,vrep.simx_opmode_oneshot_wait);
  if (res==vrep.simx_error_noerror)
    fprintf('Number of objects in the scene: %d\n',length(objs));
  else
    fprintf('Remote API function call returned with error code: %d\n',res);
  end
  [res,objs]=vrep.simxGetObjectHandle('redundantRob_joint3',vrep.simx_opmode_oneshot_wait);
  
  if (res==vrep.simx_error_noerror)
    fprintf('Got the object handle!\n');
    [res,objs2] = vrep.simxGetJointPosition(objs,vrep.simx_opmode_streaming);
    vrep.simxSetJointPosition(objs,0,vrep.simx_opmode_oneshot_wait);
    for i = 0:pi/360:pi/2
      vrep.simxSetJointPosition(objs,i,vrep.simx_opmode_oneshot_wait);
      
      if(res)
        fprintf('The joint value now: %d\n',i);
      else
        fprintf('Problem!');
        break;
      end
    end
  else
    fprintf('There was a problem...');
  end
  
  
  vrep.simxFinish();
else
  disp('Failed connecting to remote API server');
end
vrep.delete(); % explicitely call the destructor!
disp('Program ended');
end
