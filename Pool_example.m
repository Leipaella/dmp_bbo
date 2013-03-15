% Randomly chooses to give a task that will either be with an enemy ball
% behind the goal, or very close to the goal.



close all;

n_dims = 3;
n_dofs = 1; %can control starting x location, angle, and force.


%get the initial values somewhere in the ballpark
%sx power angle
distributions(1).mean = [0 5000 0];
distributions(1).covar = diag([5 1000^2 1000^2]);





obj = Skill('Pool',distributions);
obj.rollout_buffer = [];
obj.i_update = 0;
obj.n_figs = 2;
obj.idx = 0;
count = 0;

goal = [0 20];

while count < 200
  
  %percept is the location of the enemy ball in [x y]. 
  %start with 2 cases, one far away and behind, and one in front of and
  %close
  choice = rand(1);
  if choice > 0.5
    enemy = [20 40];
  else
    enemy = [5 -10];
  end
  percept = enemy;
  task = task_pool(goal,enemy);
  task_solver = task_pool_solver;

  obj = obj.solve_task_instance(task,task_solver,percept);
  count = count+1;
end