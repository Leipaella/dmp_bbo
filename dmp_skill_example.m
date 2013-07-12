function [skill] = dmp_skill_example

if (1)

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

n_rollouts_per_update = 20;
skill = Skill('two_viapoint_solver',distributions_init,n_rollouts_per_update);

% Number of updates
n_updates =  2500;
goal_learning = 0;
for i_update=1:n_updates
  task = get_new_task(g, y0);
  %             solve_task_instance(obj,task_instance, task_solver, percept,         goal_learning)
  skill = skill.solve_task_instance(    task,          task_solver, task.viapoint(1),goal_learning);

  plot_n_dofs=2;
  i_dof=1;
  subplot(plot_n_dofs,4,(i_dof-1)*4 + 2)
  axis([-10 20 -5 15]);
  axis square
  i_dof=2;
  subplot(plot_n_dofs,4,(i_dof-1)*4 + 2)
  axis([-5 20 -3 4]);
  axis square
  
  subplot(plot_n_dofs,4,4:4:plot_n_dofs*4)
  axis([0 700 0.015 0.6])
  %set(gca,'YScale','log')

  drawnow
end
return

disp('Done with learning. Plotting learning curves for all (sub)skills.');
skillplotlearningcurves(skill)

end

plot_n_dofs = 2;
for ff=[1 11 12 121 122]
  ff
  figure(ff)
  i_dof=1
  subplot(plot_n_dofs,4,(i_dof-1)*4 + 2)
  axis([-10 20 -5 15]);
  axis square
  i_dof=2
  subplot(plot_n_dofs,4,(i_dof-1)*4 + 2)
  axis([-5 20 -3 4]);
  axis square
  
  subplot(plot_n_dofs,4,4:4:plot_n_dofs*4)
  axis([0 700 0.015 0.6])
  set(gca,'YScale','log')
end

end


function task = get_new_task(g, y0)

which = rand(1);

viapoint_time_ratio =       0.25;
if which<0.25
  viapoint            = [0.45 0.7];
elseif which>0.75
  viapoint            = [0.4 0.7];
else
  viapoint            = [0.7 0.4];
end

task = task_viapoint(viapoint,viapoint_time_ratio);

end

