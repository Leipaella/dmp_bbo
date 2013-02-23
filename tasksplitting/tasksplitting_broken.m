function [theta_opt learning_history] = splitme
% This is basically a copy of evolutionaryoptimization.m with specific settings
% and some minor modifications to allow multiple optimization processes at once.

n_dims = 2;


% Initial parameters
theta_init = 10*ones(1,n_dims);
covar_init = 8*eye(n_dims);

% Algorithm parameters
n_updates = 70;
K = 20;

weighting_method = 3;
eliteness=7; % PI2 weighting

% covar_update = 0;    % Exploration does not change during learning
%covar_update = 0.9;  % Decay exploration during learning
covar_update =  2;    % Reward-weighted averaging update of covar
if (covar_update>=1)
  % For covariance matrix updating, a lower bound on the
  % eigenvalues is recommended to avoid premature convergence
  covar_bounds = [0.05 1 10]; %#ok<NBRAK> % Lower/upper bounds on covariance matrix
else
  covar_bounds = []; % No bounds
end
covar_lowpass = 0;
covar_scales = 1;

% Run optimization
clf


theta = theta_init;
[ n_dofs n_dim ] = size(theta);

covar = covar_init;
if (ndims(covar)==2)
  covar = repmat(shiftdim(covar,-1),n_dofs,[]);
end

plot_me = 1;
if (plot_me)
  clf
end
color = [0.8 0.8 0.8];
color_eval = [1 0 0];

% Start off with one task and one optimizer
n_tasks = 1;
n_optimizers = 1;

learning_histories{1} = [];
for i_update=1:n_updates



  if (i_update==1 || i_update==11)
    % Change task targets
    task_targets = -10+20*rand(n_tasks,n_dim);
    if (i_update>2)
      fprintf('Changing single target.\n   (pausing... press any key to continue)\n')
      pause
    end
  end
  
  if ( i_update==21 || i_update==51 )
    % Number of tasks is 2
    n_tasks = 2;
    % Change task targets
    task_targets(1,:) = -10+10*rand(1,n_dim);
    task_targets(2,:) =   0+10*rand(1,n_dim);
    fprintf('Changing two targets.\n   (pausing... press any key to continue)\n')
    pause
  end
  
  if (i_update>1 && n_optimizers<2)
    % Determine if we need to split the task!
    
    % Get the costs of the roll-outs from the previous run
    costs_rollouts = learning_histories{1}(end).costs_rollouts;
  
    cluster_idx = clusterdata(costs_rollouts,2);
    var_total = var(costs_rollouts);
    var_clus1 = var(costs_rollouts(cluster_idx==1));
    var_clus2 = var(costs_rollouts(cluster_idx==2));
    
    hacky_threshold = 0.1;
    fprintf('total=% 3.2f * %1.2f => %1.2f >? %1.2f = %1.2f+%1.2f (clus1+clus2)\n',var_total,hacky_threshold,hacky_threshold*var_total,var_clus1+var_clus2,var_clus1,var_clus2)
    % Hacky threshold. This should be made nicer...
    if (hacky_threshold*var_total > sum([var_clus1 var_clus2]))
      % Split!
      fprintf('Splitting into two tasks now!\n   (pausing... press any key to continue)\n')
      pause
      
      % We have two optimizers now
      n_optimizers = 2;
      % Clone the learning history of the one optimizer
      learning_histories{2} = learning_histories{1};
    end
    %colors(1,:) = [1 0 0];
    
  end

  
  if (n_optimizers==1)
    % Distribute tasks randomly for one optimizer
    for k=1:K
      % 1           1       0         0/1    (n_tasks==1)
      % 1/2         1       1         0/1    (n_tasks==2)
      choose_task = 1 + (n_tasks-1)*(rand>0.5);
      cur_target = task_targets(choose_task,:);
      tasks(1,k) = task_min_dist(cur_target);
    end
  else
    % Seperate the tasks per optimizer
    for i_optimizer=1:n_optimizers
      for k=1:K
        tasks(i_optimizer,k) = task_min_dist(task_targets(i_optimizer,:));
      end
    end
  end

  for i_optimizer=1:n_optimizers

    %------------------------------------------------------------------
    % Bookkeeping.

    % Prepare plotting of roll-outs if necessary
    if (plot_me)
      figure(i_optimizer)
      subplot(n_dofs,4,1:4:n_dofs*4)
      cla
      title('Visualization of roll-outs')
      hold on
    end

    if (i_update>1)
      % Get last updated theta from learning history
      theta = learning_histories{i_optimizer}(end).theta_new;
      covar = learning_histories{i_optimizer}(end).covar_new_bounded;
    end


    % Perform an evaluation roll-out with the current parameters and the first
    % task
    cost_eval = tasks(i_optimizer,1).perform_rollout(tasks(i_optimizer,1),theta,2*plot_me,color_eval);

    %------------------------------------------------------------------
    % Actual search

    % Generate perturbations for this update
    theta_eps = zeros(K,n_dofs,n_dim);
    for i_dof=1:n_dofs
      theta_eps(:,i_dof,:) = mvnrnd(theta(i_dof,:),squeeze(covar(i_dof,:,:)),K);
    end
    %theta_eps(1,:) = theta;

    % Perform roll-outs and record cost
    for k=1:K
      costs_rollouts(k,:) = tasks(i_optimizer,k).perform_rollout(tasks(i_optimizer,k),squeeze(theta_eps(k,:,:)),plot_me,color);
    end


    % The weights, given the costs
    weights = coststoweights(costs_rollouts(:,1),weighting_method,eliteness);

    % Perform the update for each dof separately
    for i_dof=1:n_dofs

      % Get theta, covar and theta_eps for this DOF
      cur_theta     = squeeze(theta(i_dof,:));
      cur_covar     = squeeze(covar(i_dof,:,:));
      cur_theta_eps = squeeze(theta_eps(:,i_dof,:));

      % Update the mean
      theta_new(i_dof,:) = sum(repmat(weights,1,n_dim).*cur_theta_eps,1);

      % Update covar
      [covar_new(i_dof,:,:) covar_new_bounded(i_dof,:,:) ]...
        = updatecovar(cur_theta,cur_covar,cur_theta_eps,weights,covar_update,covar_bounds,covar_lowpass,covar_scales);

    end

    %------------------------------------------------------------------
    % Bookkeeping.
    node.theta = theta;
    node.covar = covar;
    node.theta_eps = theta_eps;
    node.cost_eval = cost_eval;
    node.costs_rollouts = costs_rollouts;
    node.weights = weights;
    node.theta_new = theta_new;
    node.covar_new = covar_new;
    node.covar_new_bounded = covar_new_bounded;

    % Add this information to the history
    learning_histories{i_optimizer}  = [learning_histories{i_optimizer}  node];


    if (plot_me)
      % Done with plotting of roll-outs
      subplot(n_dofs,4,1:4:n_dofs*4)
      hold off

      plotlearninghistory(learning_histories{i_optimizer});
      subplot(n_dofs,4,2)
      axis equal
      axis(2*[-10 10 -10 10])
      drawnow
      
      if (isfield(tasks(i_optimizer,1),'plotlearninghistorycustom'))
        figure(11)
        tasks(i_task).plotlearninghistorycustom(learning_histories{i_optimizer})
      end

      %fprintf('Pausing... press key to continue.\n'); pause
    end


    %------------------------------------------------------------------
    % Replace the old with the new. Such is life.
    theta = theta_new;
    covar = covar_new_bounded;
  end

end

% Done with optimizing. Return optimal (?) parameters
theta_opt = theta;

% Here is an example of how to design a task. This one simply returns the
% distance to the dist.
  function [task] = task_min_dist(target)

    task.name = 'min_dist';
    task.perform_rollout = @perform_rollout_min_dist;
    task.target = target;
    task.n_dims = length(target);

    % Now comes the function that does the roll-out and visualization thereof
    function cost = perform_rollout_min_dist(task,theta,plot_me,color)

      % Cost is distance to dist
      cost = sqrt(sum((theta(:)-target(:)).^2));

      % Plot if necessary
      if (nargin>2 && plot_me)
        if (nargin<4)
          color = [0 0 0.6];
        end
        if (task.n_dims==2)
          plot([task.target(1) theta(1)],[task.target(2) theta(2)],'-','Color',color)
          plot(theta(1),theta(2),'o','Color',color)
          plot(task.target(1),task.target(2),'*g')
          axis equal
          axis(2*[-10 10 -10 10])
        elseif (task.n_dims==3)
          plot3([task.target(1) theta(1)],[task.target(2) theta(2)],[task.target(3) theta(3)],'-','Color',color)
          plot3(theta(1),theta(2),theta(3),'o','Color',color)
          plot3(task.target(1),task.target(2),task.target(3),'*g')
          axis equal
          axis(2*[-10 10 -10 10 -10 10])
          view(45,45)
        end
      end

    end

  end


end