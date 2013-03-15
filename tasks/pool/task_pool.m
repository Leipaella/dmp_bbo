function [task] = task_pool(goal, enemy)
if (nargin<1), goal = [0 0]; end
if (nargin<2), enemy = [-10 -10]; end
task.name = 'pool';

task.goal = goal;
task.enemy = enemy;

task.cost_function= @cost_function_pool;


  function costs = cost_function_pool(task,cost_vars)
    %cost_vars contains [x y] for the enemy and for the cue ball
    
    %[n_rollouts n_cost_vars ] = size(cost_vars); %#ok<NASGU>
    n_rollouts = 1;
    for k = 1:n_rollouts
      cue_to_goal = sqrt(sum((cost_vars(1,:) - task.goal).^2));
      enemy_to_goal = sqrt(sum((cost_vars(2,:) - task.goal).^2));
      
      costs(k,2) = cue_to_goal; %the closer you are, the better.
      costs(k,3) = -enemy_to_goal; %the further the enemy is, the better
      costs(k,1) = sum(costs(2:end));
      disp(['cue_to_goal: ' num2str(cue_to_goal) ' enemy_to goal: ' num2str(enemy_to_goal) ' total cost: ' num2str(costs(k,1))]); 
    end
    
  end

end

