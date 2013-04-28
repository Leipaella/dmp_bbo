
function run_simulation(filename)

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
  
  %get all joint handles
  [res1,joint1]=vrep.simxGetObjectHandle('redundantRob_joint1',vrep.simx_opmode_oneshot_wait);
  [res2,joint2]=vrep.simxGetObjectHandle('redundantRob_joint2',vrep.simx_opmode_oneshot_wait);
  [res3,joint3]=vrep.simxGetObjectHandle('redundantRob_joint3',vrep.simx_opmode_oneshot_wait);
  [res4,joint4]=vrep.simxGetObjectHandle('redundantRob_joint4',vrep.simx_opmode_oneshot_wait);
  [res5,joint5]=vrep.simxGetObjectHandle('redundantRob_joint5',vrep.simx_opmode_oneshot_wait);
  [res6,joint6]=vrep.simxGetObjectHandle('redundantRob_joint6',vrep.simx_opmode_oneshot_wait);
  [res7,joint7]=vrep.simxGetObjectHandle('redundantRob_joint7',vrep.simx_opmode_oneshot_wait);
  
  if all([res1 res2 res3 res4 res5 res6 res7] == vrep.simx_error_noerror)
    fprintf('Succeeded in getting the joint handles!\n');
    %set the initial angles
    vrep.simxSetJointPosition(joint1,0,vrep.simx_opmode_oneshot_wait);
    vrep.simxSetJointPosition(joint2,0,vrep.simx_opmode_oneshot_wait);
    vrep.simxSetJointPosition(joint3,0,vrep.simx_opmode_oneshot_wait);
    vrep.simxSetJointPosition(joint4,0,vrep.simx_opmode_oneshot_wait);
    vrep.simxSetJointPosition(joint5,0,vrep.simx_opmode_oneshot_wait);
    vrep.simxSetJointPosition(joint6,0,vrep.simx_opmode_oneshot_wait);
      
    for i = 0:-pi/360:-pi/3.5
      %vrep.simxPauseCommunication(1); %need to pause to send all commands at once
      %vrep.simxSetJointPosition(joint1,i,vrep.simx_opmode_oneshot_wait);
      vrep.simxSetJointPosition(joint2,i,vrep.simx_opmode_oneshot_wait);
      %vrep.simxSetJointPosition(joint3,i,vrep.simx_opmode_oneshot_wait);
      %vrep.simxSetJointPosition(joint4,0,vrep.simx_opmode_oneshot_wait);
      %vrep.simxSetJointPosition(joint5,0,vrep.simx_opmode_oneshot_wait);
      vrep.simxSetJointPosition(joint6,i,vrep.simx_opmode_oneshot_wait);
      %vrep.simxSetJointPosition(joint7,0,vrep.simx_opmode_oneshot_wait);
      %vrep.simxPauseCommunication(0); %now send the commands!
      
    end
  else
    fprintf('There was a problem...\n');
  end
  
  
  vrep.simxFinish();
else
  disp('Failed connecting to remote API server');
end
vrep.delete(); % explicitely call the destructor!
disp('Program ended');
end
