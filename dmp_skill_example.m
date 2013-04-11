function dmp_skill_example

addpath dynamicmovementprimitive
addpath(genpath('evolutionaryoptimization/'))
addpath(genpath('tasks/'))
addpath(genpath('skills/'))

g = [1.0 1.0];
y0 = [0.0 0.0];
 
evaluation_external_program = 0;
task_solver = task_viapoint_solver_dmp(g,y0,evaluation_external_program);

% Initial means
theta_init = zeros(2,2);
% Initial covariance matrix for exploration
covar_init = 5*eye(size(theta_init,2));


% Number of updates, roll-outs per update
n_updates =  25;
n_samples =  15;

% Weighting method, and covariance update method
update_parameters.weighting_method    = 'PI-BB'; % {'PI-BB','CMA-ES'}
update_parameters.eliteness           =      10;
update_parameters.covar_update        = 'PI-BB'; % {'PI-BB','CMA-ES'}
update_parameters.covar_full          =       0; % 0 -> diag, 1 -> full
update_parameters.covar_learning_rate =     0.8; % No lowpass filter
update_parameters.covar_bounds        =   [0.1 0.01]; 


distributions_init.mean = theta_init;
distributions_init.covar = covar_init;

skill = Skill('two_viapoint_solver',distributions_init);
i_update = 1;

while(i_update < n_updates)
  task = get_new_task(g, y0);
  skill = skill.solve_task_instance(task);
  i_update = i_update + 1;

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

