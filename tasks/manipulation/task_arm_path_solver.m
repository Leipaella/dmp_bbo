function [task_solver] = task_arm_path_solver(y0,evaluation_external_program,g)
task_solver.name = 'task_arm_path_solver';

%if goal is given, save it, otherwise we will assume that the goal is the
%last 6 parameters being optimized.
task_solver.g = [];
if (nargin>2), task_solver.g = g; end

if (evaluation_external_program)
  task_solver.perform_rollouts = @perform_rollouts_viapoint_solver_dmp_external;
else
  task_solver.perform_rollouts = @perform_rollouts_viapoint_solver_dmp;
end

task_solver.plot_rollouts = @plot_rollouts_viapoint_solver_dmp;

% Initial state
task_solver.y0 = y0;

% DMP settings related to time
task_solver.time = 1;
task_solver.dt = 1/50;
task_solver.time_exec = 1.2;
task_solver.timesteps = ceil(1+task_solver.time_exec/task_solver.dt); % Number of time steps

task_solver.order=2; % Order of the dynamic movement primitive
% Next values optimized for minimizing acceleration in separate learning session
%task.theta_init = [37.0458   -4.2715   27.0579   13.6385; 37.0458   -4.2715   27.0579   13.6385];
task_solver.theta_init = zeros(2,2);

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
        trajectories(k) = dmpintegrate(task_solver.y0,task_solver.g,theta,task_solver.time,task_solver.dt,task_solver.time_exec);
      end
    end
    
    %we need to write the path data to a path file
    return_dir = cd;
    directory = 'C:\Program Files (x86)\V-REP3\V-REP_PRO_EDU';
    cd(directory);
    csvwrite('trajectory.csv',trajectories.y);
    %cd(return_dir);
    %find task filename
    switch task.id
      case 1, filename = 'task1.ttt';
      case 2, filename = 'task2.ttt';
      otherwise, disp('Task id not recognized');
    end
    
    if exist('cost_vars.csv','file')
      delete('cost_vars.csv');
    end
    
    % Run external program here
    vrep=remApi('remoteApi','extApi.h');
    clientID = vrep.simxStart('127.0.0.1',19999,true,true,5000);
    if (clientID > -1)
      disp('Connected to remote API server');
      %load the applicable file
      res2 = vrep.simxLoadScene('task.ttt',false,vrep.simx_opmode_oneshot_wait);
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
      vrep.simxFinish();
    end
    vrep.delete(); 
    cost_vars = csvread('cost_vars.csv');
    cd(return_dir);
  end


end

