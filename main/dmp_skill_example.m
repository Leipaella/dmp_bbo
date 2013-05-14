
goal_learning = 1;

distributions = [];
g                   = [1.0 1.0];
y0                  = [0.0 0.0];
evaluation_external_program = 0; % This runs the evaluation of costs in an external program (i.e. not Matlab)

goal = [1.0 1.0];

% A very simple 2-D DMP viapoint task
viapoint            = [0.4 0.7];
viapoint_time_ratio =       0.3;
task = task_viapoint(viapoint,viapoint_time_ratio);
task_solver = task_viapoint_solver_dmp(g,y0,evaluation_external_program);

theta_init = task_solver.theta_init;
% Initial covariance matrix for exploration
covar_init = 5*eye(size(task_solver.theta_init,2));


% Number of updates, roll-outs per update
n_updates =  200;
n_samples =  15;

% Weighting method, and covariance update method
update_parameters.weighting_method    = 'PI-BB'; % {'PI-BB','CMA-ES'}
update_parameters.eliteness           =      10;
update_parameters.covar_update        = 'PI-BB'; % {'PI-BB','CMA-ES'}
update_parameters.covar_full          =       0; % 0 -> diag, 1 -> full
update_parameters.covar_learning_rate =     0.8; % No lowpass filter
update_parameters.covar_bounds        =   [0.1 0.01]; %#ok<NBRAK> 



[ n_dofs n_dims ] = size(theta_init); %#ok<NASGU>
if (ndims(covar_init)==2)
  covar_init = repmat(shiftdim(covar_init,-1),n_dofs,[]);
end
if ~goal_learning
  for i_dof=1:n_dofs
    distributions(i_dof).mean  = theta_init(i_dof,:);
    distributions(i_dof).covar = squeeze(covar_init(i_dof,:,:));
  end
else
  for i_dof=1:n_dofs
    distributions(i_dof).mean  = theta_init(i_dof,:);
    distributions(i_dof).covar = squeeze(covar_init(i_dof,:,:));
  end
  %add a degree of freedom for the goal
  distributions(n_dofs+1).mean = 1.0;
  distributions(n_dofs+1).covar = 0.2;
  distributions(n_dofs+2).mean = 1.0;
  distributions(n_dofs+2).covar = 0.2;
  %task solver
  task_solver = task_goal_viapoint_solver_dmp(g,y0,evaluation_external_program,1);

end


obj = Skill('Viapoint',distributions);
obj.n_figs = 1;
obj.K = n_samples;
percept = 1;

for i = 1:n_samples*n_updates
  
  if goal_learning 
    task = task_goal_viapoint(viapoint,viapoint_time_ratio,goal);
  else
    task_solver = task_viapoint_solver_dmp(g,y0,evaluation_external_program);
  end
  
  obj = obj.solve_task_instance(task,task_solver,percept,goal_learning);
  drawnow;
end


%clf
%evolutionaryoptimization(task,task_solver,task_solver.theta_init,covar_init,n_updates,n_samples,update_parameters)

