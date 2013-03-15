function [task_solver] = task_pool_solver



task_solver.perform_rollouts = @perform_rollouts_pool;
task_solver.plot_rollouts = @plot_rollouts_pool;


% Now comes the function that does the roll-out and visualization thereof
  function cost_vars = perform_rollouts_pool(task,thetas) %#ok<INUSL>
    
    %thetas contain three variables.
    % the x position, the power, and the angle
    sx = thetas(1);
    power = thetas(2);
    angle = thetas(3);
    
    cost_vars = pool(task.enemy,[angle power], [sx -40]);
    
  end

 function plot_rollouts_pool(axes_handle,task,cost_vars)

    %subplot(1,3,1);
    hold on;
    plot(task.goal(1),task.goal(2),'gx');
    plot(cost_vars(1,1),cost_vars(1,2),'kx');
    plot(cost_vars(2,1),cost_vars(2,2),'rx');
    axis([-25 25 -50 50]);
    axis equal;
    
  end
end

