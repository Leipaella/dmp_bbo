% Randomly chooses to give a task that will either be with an enemy ball
% behind the goal, or very close to the goal.



close all;

%n_dims = 3;
n_dofs = 1; %can control starting x location, angle, and force.


%get the initial values somewhere in the ballpark
%sx power angle
%distributions(1).mean = [0 5000 0];
%distributions(1).covar = diag([5 1000^2 1000^2]);

n_dims = 2;
distributions(1).mean = [45 pi/2];
distributions(1).covar = diag([5^2 (pi/8)^2]);




obj = Skill('Pool',distributions);
obj.rollout_buffer = [];
obj.i_update = 0;
obj.n_figs = 3;
obj.idx = 0;
count = 0;
goal = [25 75];



  [tasks percepts ntasks] = generate_unique_tasks(goal);

while count < 4000
  
  p = randperm(ntasks);
  
  
  
  
  %percept can be their polar coordinates from the goal for example. and
  %which team
  %r = sqrt((x - goal(1)).^2 + (y - goal(2)).^2);
  %t = atan2((y - goal(2)),(x - goal(1)));
  %percept(1:2) = r;
  %percept(3:4) = t;
  %percept(5:6) = teams;
  
  %make the percept simple
  %percept = [];
  %percept(1) = p(1) - 1;
  
  %task = task_pool(goal,balls);
  
  task = tasks(p(1));
  percept = percepts(p(1),:);
  task_solver = task_pool_solver;
  
  obj = obj.solve_task_instance(task,task_solver,percept);
  count = count + 1;
  disp(count);
end





timestr = datestr(clock);
timestr(timestr == ' ') = '_';
timestr(timestr == ':') = '-';

save(timestr,'obj','percepts','tasks','task_solver');
