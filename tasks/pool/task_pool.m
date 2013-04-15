function [task] = task_pool(goal, balls,id,n)
if (nargin<1), goal = [25 75]; end
if (nargin<2), balls = []; end
if (nargin<3), id = 1; end
if (nargin<4), n = 1; end

task.name = 'pool';
task.id = id;
task.goal = goal;
task.balls = balls;
task.n = n;

task.cost_function= @cost_function_pool;


  function costs = cost_function_pool(task,cost_vars)
    %cost_vars contains end positions for all balls, and which team each
    %ball is on.
    
    cost = 0;
    initial_cost = 0;
    N = size(cost_vars.X,2);
    for ii = 2:N %for each ball
      if cost_vars.teams(ii) == 1 %it's on our team
        initial_cost = initial_cost + sqrt((task.balls.x(ii-1) - task.goal(1)).^2 + (task.balls.y(ii-1) - task.goal(2)).^2);
        cost = cost + sqrt((cost_vars.X(ii) - task.goal(1)).^2 + (cost_vars.Y(ii) - task.goal(2)).^2);
        
        my_closest_dist = sqrt((cost_vars.X(ii) - task.goal(1)).^2 + (cost_vars.Y(ii) - task.goal(2)).^2);
      else %it's on the opponent's team
        initial_cost = initial_cost - sqrt((task.balls.x(ii-1) - task.goal(1)).^2 + (task.balls.y(ii-1) - task.goal(2)).^2);
        cost = cost - sqrt((cost_vars.X(ii) - task.goal(1)).^2 + (cost_vars.Y(ii) - task.goal(2)).^2);
        
        their_closest_dist = sqrt((cost_vars.X(ii) - task.goal(1)).^2 + (cost_vars.Y(ii) - task.goal(2)).^2);
      end
    end
    cost = cost + sqrt((cost_vars.X(1) - task.goal(1)).^2 + (cost_vars.Y(1) - task.goal(2)).^2);
    my_closest_dist =  sqrt((cost_vars.X(1) - task.goal(1)).^2 + (cost_vars.Y(1) - task.goal(2)).^2);
    costs = cost - initial_cost;
    %cost will be a binary of who's closer. 0 if you are, 1 if the enemy
    %is.
    %costs = my_closest_dist > their_closest_dist;
    
    
%     %[n_rollouts n_cost_vars ] = size(cost_vars); %#ok<NASGU>
%     n_rollouts = 1;
%     for k = 1:n_rollouts
%       cue_to_goal = sqrt(sum((cost_vars(1,:) - task.goal).^2));
%       enemy_to_goal = sqrt(sum((cost_vars(2,:) - task.goal).^2));
%       
%       costs(k,2) = cue_to_goal; %the closer you are, the better.
%       costs(k,3) = -enemy_to_goal; %the further the enemy is, the better
%       costs(k,1) = sum(costs(2:end));
%       disp(['cue_to_goal: ' num2str(cue_to_goal) ' enemy_to goal: ' num2str(enemy_to_goal) ' total cost: ' num2str(costs(k,1))]); 
%    end
    
  end

end

