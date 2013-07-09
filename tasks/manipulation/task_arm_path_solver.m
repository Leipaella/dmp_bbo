function [task_solver] = task_arm_path_solver(y0,evaluation_external_program,g)
task_solver.name = 'task_arm_path';

%if goal is given, save it, otherwise we will assume that the goal is the
%last 6 parameters being optimized.
task_solver.g = [];
task_solver.old_task_id = -1;
if (nargin>2), task_solver.g = g; end

if (evaluation_external_program)
  task_solver.perform_rollouts = @perform_rollouts_viapoint_solver_dmp_external;
else
  task_solver.perform_rollouts = @perform_rollouts_viapoint_solver_dmp;
end

%initiallize the connection to vrep
task_solver.vrep=remApi('remoteApi','extApi.h');
task_solver.clientID = task_solver.vrep.simxStart('127.0.0.1',19999,true,true,5000);
    

%task_solver.plot_rollouts = @plot_rollouts_viapoint_solver_dmp;

% Initial state
task_solver.y0 = y0;

% DMP settings related to time
task_solver.time = 1;
task_solver.dt = 1/50;
task_solver.time_exec = 1.2;
task_solver.timesteps = ceil(1+task_solver.time_exec/task_solver.dt); % Number of time steps
task_solver.close_sim = @close_vrep;
%task_solver.order=2; % Order of the dynamic movement primitive
% Next values optimized for minimizing acceleration in separate learning session
%task.theta_init = [37.0458   -4.2715   27.0579   13.6385; 37.0458   -4.2715   27.0579   13.6385];
%task_solver.theta_init = zeros(2,2);

%addpath dynamicmovementprimitive/

  function plot_rollouts_viapoint_solver_dmp(axes_handle,task,cost_vars)
    cla(axes_handle)
    
    x = squeeze(cost_vars(:,:,1));
    y = squeeze(cost_vars(:,:,4));
    n_time_steps = task_solver.timesteps;
    viapoint_time_step = round(task.viapoint_time_ratio*n_time_steps);

    linewidth = 1;
    color = 0.8*ones(1,3);
    plot(x(2:end,viapoint_time_step),y(2:end,viapoint_time_step),'o','Color',color,'LineWidth',linewidth)
    hold on
    plot(x(2:end,:)',y(2:end,:)','Color',color,'LineWidth',linewidth)
    my_ones = ones(size(x(2:end,viapoint_time_step)));
    plot([ x(2:end,viapoint_time_step) task.viapoint(1)*my_ones]' ,[y(2:end,viapoint_time_step) task.viapoint(2)*my_ones]','Color',color,'LineWidth',linewidth)

    linewidth = 2;
    color = 0.5*color;
    plot(x(1,viapoint_time_step),y(1,viapoint_time_step),'o','Color',color,'LineWidth',linewidth)
    plot(x(1,:)',y(1,:)','Color',color,'LineWidth',linewidth)
    plot([ x(1,viapoint_time_step) task.viapoint(1)] ,[y(1,viapoint_time_step) task.viapoint(2)],'Color',color,'LineWidth',linewidth)

    plot(task.viapoint(1),task.viapoint(2),'og')
    
    hold off
    axis([-0.1 1.1 -0.1 1.1])
  end

% Now comes the function that does the roll-out and visualization thereof
  function cost_vars = perform_rollouts_viapoint_solver_dmp(task,thetas) %#ok<INUSL>
    
    n_samples = size(thetas,2);
    n_dims = length(task_solver.g);
    order = size(thetas,3); %order is the number of basis functions
    n_time_steps = task_solver.timesteps;

    cost_vars = zeros(n_samples,n_time_steps,3*n_dims); % Compute n_timesteps and n_dims in constructor
    
    for k=1:n_samples
      theta = squeeze(thetas(:,k,:));
    
      trajectory = dmpintegrate(task_solver.y0,task_solver.g,theta,task_solver.time,task_solver.dt,task_solver.time_exec,order);
      
      cost_vars(k,:,1:3:end) = trajectory.y;
      cost_vars(k,:,2:3:end) = trajectory.yd;
      cost_vars(k,:,3:3:end) = trajectory.ydd;
    
    end
    
  end

% Now comes the function that does the roll-out and visualization thereof
  function cost_vars = perform_rollouts_viapoint_solver_dmp_external(task,thetas)
      
    n_samples = size(thetas,2);
    for k=1:n_samples
      theta = squeeze(thetas(:,k,:));
      if ~isempty(task_solver.g)
        trajectories(k) = dmpintegrate(task_solver.y0,task_solver.g,theta,task_solver.time,task_solver.dt,task_solver.time_exec);
      else
        theta2 = theta(1:end-6,:);
        goal = theta(end-5:end,1)';
        %add noise
        noise = (rand([1 6]) - 0.5).*[0.005 0.005 0.005 2*pi/180 2*pi/180 2*pi/180];
        %goal = goal + noise;
        trajectories(k) = dmpintegrate(task_solver.y0,goal,theta2,task_solver.time,task_solver.dt,task_solver.time_exec);
      end
    end
    
    %we need to write the path data to a path file
    return_dir = cd();
    if (~isempty(findstr(pwd,'stulp')))
      directory = '~stulp/prog/matlab/dmp_bbo/vrepversions/V-REP_PRO_EDU_V3_0_4_Linux/';
    else
      directory = 'C:\Program Files (x86)\V-REP3\V-REP_PRO_EDU';
    end
    cd(directory);
    
    
    settleT = 100;
    settleT2 = 30;
    %tack on additions
    traj = trajectories.y;
    traj = [traj zeros(size(traj,1),1)]; %add column for gripper
    settle1 = repmat(traj(end,:),settleT,1);
    close_gripper = repmat(traj(end,:),50,1);%close gripper, giving it 10 time steps to close
    close_gripper(:,end) = 1;
    lift = repmat(traj(end,:),30,1);%lift up in the z direction by 0.2
    lift(:,3) = linspace(lift(1,3),lift(1,3)+0.2,size(lift,1));
    settle2 = repmat(lift(end,:),settleT2,1); %let settle to final position
    
    traj = cat(1,traj,settle1,close_gripper,lift,settle2);
    %avoid self collisions by limiting beta to be less than pi/2
    traj(traj(:,5)>(pi/2-pi/180),5) = pi/2 - pi/180;
    
    csvwrite('trajectory.csv',traj);
    %cd(return_dir);
    %find task filename
%     switch task.id
%       case 1, filename = 'task1.ttt';
%       case 2, filename = 'task2.ttt';
%       otherwise, disp('Task id not recognized');
%     end
    
    filename = task.filename;
    
    if exist('cost_vars.csv','file')
      delete('cost_vars.csv');
    end
    
    % Run external program here
    %vrep=remApi('remoteApi','extApi.h');
    %clientID = vrep.simxStart('127.0.0.1',19999,true,true,5000);
    vrep = task_solver.vrep;
    clientID = task_solver.clientID;
    if (clientID > -1)
      disp('Connected to remote API server');
      %load the applicable file
      %only load file if the current task is different from the last task
      if task.id ~= task_solver.old_task_id
        if (~isempty(findstr(pwd,'stulp')))
          res2 = vrep.simxLoadScene(task_solver.clientID,filename,false,vrep.simx_opmode_oneshot_wait);
        else
          res2 = vrep.simxLoadScene(filename,false,vrep.simx_opmode_oneshot_wait);
        end
        task_solver.old_task_id = task.id;
      else
          res2 = vrep.simx_error_noerror;
      end
      if res2==vrep.simx_error_noerror
        fprintf('Loaded the file %s\n',filename);
        %run the simulation
        vrep.simxStartSimulation(vrep.simx_opmode_oneshot);
      else
        fprintf('Did not successfully load the file\n');
      end
      %next see if cost file appears or not, when it does, stop the
      %simulation.
      %cd(directory);
      while ~exist('cost_vars.csv','file')
        pause(0.1)
        fprintf('.');
      end
      
      vrep.simxStopSimulation(vrep.simx_opmode_oneshot);
      %vrep.simxCloseScene(vrep.simx_opmode_oneshot_wait);
    end
    pause(0.5);
    cost_vars = csvread('cost_vars.csv');
    cd(return_dir);
    if (~isempty(findstr(pwd,'stulp')))
      cd('~stulp/prog/matlab/dmp_bbo/rollouts');
    else
      cd('C:\Users\laura\dmp\dmp_bbo\rollouts');
    end
    if ~exist(task_solver.name,'dir'), mkdir(task_solver.name); end
    cd(task_solver.name);
    files = dir('traj*');
    n_files = length(files);
    csvwrite(sprintf('trajectory%04d.csv',n_files+1),traj);
    csvwrite(sprintf('costvars%04d.csv',n_files+1),cost_vars);
    
  end

    function close_vrep
       task_solver.vrep.simxFinish();
       task_solver.vrep.delete();  
    end



end

