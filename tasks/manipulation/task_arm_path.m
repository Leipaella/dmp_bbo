function [task] = task_arm_path(eigenvals,eigenvecs)

task.name = 'task_arm_path';
if nargin<2
else
task.eigenvals = eigenvals;
task.eigenvecs = eigenvecs;
end
task.cost_function= @cost_function_arm_path;



  function costs = cost_function_arm_path(task,cost_vars)
    
    
    
    %here is the cost function
    %the cost will be related to whether the object is aproximately
    %equivalent in orientation to when it started, and whether it was
    %successfully gripped or not.
    
    position = cost_vars(1,:);
    angles = cost_vars(2,:);
    angles(angles>pi) = angles(angles>pi) - 2*pi;
    force_measured = cost_vars(3,1);
    self_coll = cost_vars(4,1);
    environ_coll = cost_vars(4,2);
    
    %three things contribute to the cost all between 0 and 1, 0 being the
    %best and 1 being the worst
    
    % 1. Change in Z -> did the object actually lift?
    lift = 1 - position(3)/0.2; %0.2 is the height the arm lifted
    % 2. Change in orientation -> is the object the same orientation in the
    % air as on the floor?
    orientation = sum(angles)/(3*pi); %worst would be to fully rotate
    % 3. Force applied -> want to minimize in order to find the easiest
    % grip
    force = abs(force_measured/300); %-300 is the maximum force
    
    
    cost_weights = [4 2 1];
    cost_weights = cost_weights/sum(cost_weights);
    
    costs = cost_weights*[lift; orientation; force]; 
    
    if self_coll
      costs = 1;
    end
    
    
  end

end

