function dmp_skill_example

addpath dynamicmovementprimitive
addpath(genpath('evolutionaryoptimization/'))
addpath(genpath('tasks/'))
addpath(genpath('skills/'))

g = [1.0 1.0];
y0 = [0.0 0.0];
n_dofs = length(g);
 
evaluation_external_program = 0;
task_solver = task_viapoint_solver_dmp(g,y0,evaluation_external_program);

n_basis_functions = 3;
% Initial means
theta_init = zeros(1,n_basis_functions);
% Initial covariance matrix for exploration
covar_init = 5*eye(n_basis_functions);
% Put the above in the distributions structure
for dd=1:n_dofs
  distributions_init(dd).mean = theta_init;
  distributions_init(dd).covar = covar_init;
end

n_rollouts_per_update = 20;
skill = Skill('two_viapoint_solver',distributions_init,n_rollouts_per_update);

% Number of updates
n_updates =  100;
goal_learning = 0;
for i_update=1:n_updates
  task = get_new_task(g, y0);
  %             solve_task_instance(obj,task_instance, task_solver, percept,         goal_learning)
  skill = skill.solve_task_instance(    task,          task_solver, task.viapoint(1),goal_learning);
end

end


function task = get_new_task(g, y0)

which = rand(1);

if which>0.5
  viapoint            = [0.4 0.7];
  viapoint_time_ratio =       0.3;  
else
  viapoint            = [0.7 0.4];
  viapoint_time_ratio =       0.3; 
end

task = task_viapoint(viapoint,viapoint_time_ratio);

end

