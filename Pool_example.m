% Randomly chooses to give a task that will either be with an enemy ball
% behind the goal, or very close to the goal.



close all;

%n_dims = 3;
n_dofs = 1; %can control starting x location, angle, and force.


%get the initial values somewhere in the ballpark
%sx power angle
%distributions(1).mean = [0 5000 0];
%distributions(1).covar = diag([5 1000^2 1000^2]);

n_dims = 1;
distributions(1).mean = 5000;
distributions(1).covar = 1000^2;




obj = Skill('Pool',distributions);
obj.rollout_buffer = [];
obj.i_update = 0;
obj.n_figs = 3;
obj.idx = 0;
count = 0;

goal = [0 20];

while count < 400
  
  %percept is the location of the enemy ball in [x y], whether the enemy ball is
  %in front of (1) or behind (0) the goal, whether the enemy ball is to the
  %left or right of the goal
  %
  % enemy position [x y] discretized
  % enemy in front/behind = 0/1
  % enemy left/right = 0/1
  
  %start with 2 cases, one far away and behind, and one in front of and
  %close
  choice = randi(2);
  switch choice
      case 1, enemy = goal + [0 10];
      case 2, enemy = goal + [0 -10];
      %case 3, enemy = goal + [10 10];
      %case 4, enemy = goal + [10 -10];
  end
  
  noise = rand(1,2)*3;
  %enemy = enemy + noise;
  %percept(1:2) = enemy;
  
  %front/back
  if(enemy(2) <= goal(2))
      percept(1) = 0; %in front of the goal
  else
      percept(1) = 1; %behind the goal
  end
  
  %left/right
  if(enemy(1) <= goal(1))
      percept(2) = 0;
  else
      percept(2) = 1;
  end
  
  task = task_pool(goal,enemy);
  task_solver = task_pool_solver;

  obj = obj.solve_task_instance(task,task_solver,percept);
  count = count+1;
end