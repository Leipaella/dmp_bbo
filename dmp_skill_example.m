function [skill] = dmp_skill_example

addpath dynamicmovementprimitive
addpath(genpath('evolutionaryoptimization/'))
addpath(genpath('tasks/'))
addpath(genpath('skills/'))

g = [1.0 1.0];
y0 = [0.0 0.0];
n_dofs = length(g);
 
evaluation_external_program = 0;
task_solver = task_viapoint_solver_dmp(g,y0,evaluation_external_program);

% Number of basis functions in the DMP
n_basis_functions = 2;
% Initialize the distributions
for dd=1:n_dofs
  distributions_init(dd).mean  = zeros(1,n_basis_functions);
  distributions_init(dd).covar = 5*eye(n_basis_functions);
end

n_rollouts_per_update = 16;
skill = Skill('two_viapoint_solver',distributions_init,n_rollouts_per_update);
skill.n_figs = 2;

% Number of updates
n_updates =  250;
goal_learning = 0;
for i_update=1:n_updates
  task = get_new_task(g, y0);
  %             solve_task_instance(obj,task_instance, task_solver, percept,         goal_learning)
  skill = skill.solve_task_instance(    task,          task_solver, task.viapoint(1),goal_learning);
end

disp('Done with learning. Plotting learning curves for all (sub)skills.');
% Plot learning curves for all skills
skill_stack{1} = skill;
while (~isempty(skill_stack))
  
  % Pop first skill
  cur_skill = skill_stack{1};
  skill_stack(1) = [];

  % Plot its learning history
  figure(cur_skill.idx)
  clf
  plotlearninghistory(cur_skill.learning_history);
  
  % Push any children on the stack
  for ss=1:length(cur_skill.subskills)
    skill_stack{end+1} = cur_skill.subskills(ss);
  end
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

