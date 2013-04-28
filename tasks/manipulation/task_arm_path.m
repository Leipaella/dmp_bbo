function [task] = task_arm_path(eigenvals,eigenvecs)

task.name = 'task_arm_path';
task.eigenvals = eigenvals;
task.eigenvecs = eigenvecs;
task.cost_function= @cost_function_arm_path;


  function costs = cost_function_arm_path(task,cost_vars)
    
    %here is the cost function
    %the cost will be related to whether the object is aproximately
    %equivalent in orientation to when it started, and whether it was
    %successfully gripped or not.
    
    [n_rollouts n_time_steps n_cost_vars ] = size(cost_vars); 
    viapoint_time_step = round(task.viapoint_time_ratio*n_time_steps);
    
    for k=1:n_rollouts
      ys   = squeeze(cost_vars(k,:,1:3:end));
      ydds = squeeze(cost_vars(k,:,3:3:end));

      dist_to_viapoint = sqrt(sum((ys(viapoint_time_step,:)-viapoint).^2));
      costs(k,2) = dist_to_viapoint;

      % Cost due to acceleration
      sum_ydd = sum((sum(ydds.^2,2)));
      costs(k,3) = sum_ydd/10000;

      % Total cost is the sum of all the subcomponent costs
      costs(k,1) = sum(costs(k,2:end));
    end
  end

end

