function [theta_opt learning_history] = evolutionaryoptimization(task,theta_init,covar_init,n_updates,K,eliteness,weighting_method,covar_update,covar_bounds,covar_scales)
% Input:
%  task             - task that should be optimized
%  theta_init       - initial parameters
%  covar_init       - initial covariance matrix for exploration
%  n_updates        - number of updates to perform
%  K                - number of roll-outs per update
%  eliteness        - number elite samples per update
%  weighting_method - for reward-weighted averaging
%                       1 - Cross-entropy method weights
%                       2 - CMAES default weights
%                       3 - PI^2 weights
%  covar_update     - determines decay of the exploration (should be in range <0,1])
%                       0     - No updating, covariance matrix does not change
%                       <0-1> - Decaying exploration
%                       1     - Update diagonal through reward-weighted averaging
%                       2     - Update full covariance matrix through reward-weighted averaging
%  covar_bounds     - lower/upper bounds on the covariance matrix eigenvalues
%                       Takes form [lower_relative lower_absolute upper_absolute]
%                       lower_relative - none of the covariance matrix'
%                                        eigenvalues may be smaller than
%                                        lower_relative times the largest
%                                        eigenvalue
%                                        default: 0.01
%                       lower_absolute - none of the covariance matrix'
%                                        eigenvalues may be smaller than
%                                        lower_absolute
%                                        default: no bound
%                       upper_absolute - none of the covariance matrix'
%                                        eigenvalues may be smaller than
%                                        upper_absolute
%                                        default: no bound
%
%  covar_scales - scaling factor for covar (work in progress)

if (nargin==0)
  [theta_opt learning_history] = testevolutionaryoptimization;
  return
end

if (nargin<3); covar_init = eye(size(theta_init,2)); end
if (nargin<4); n_updates = 50; end
if (nargin<5); K = 10; end
if (nargin<6); eliteness = round(K/2); end
% weighting_method
%  1 - Cross-entropy method weights
%  2 - CMAES default weights
%  3 - PI^2 weights
if (nargin<7); weighting_method = 3; end
if (nargin<8); covar_update = 2; end % Full update of covar
if (nargin<9); covar_bounds = [0.1]; end %#ok<NBRAK> % Lower relative bound
if (nargin<10); covar_scales = 1; end % No scaling

theta = theta_init;
[ n_dofs n_dim ] = size(theta);

covar = covar_init;
if (ndims(covar)==2)
  covar = repmat(shiftdim(covar,-1),n_dofs,[]);
end

plot_me = 1;
if (plot_me)
  clf
  color = [0.8 0.8 0.8];
  color_eval = [1 0 0];
end

learning_history = [];
for i_update=1:n_updates

  %------------------------------------------------------------------
  % Bookkeeping.

  % Prepare plotting of roll-outs if necessary
  if (plot_me)
    figure(1)
    subplot(n_dofs,4,1:4:n_dofs*4)
    cla
    title('Visualization of roll-outs')
    hold on
  end

  % Perform an evaluation roll-out with the current parameters
  cost_eval = task.perform_rollout(task,theta,2*plot_me,color_eval);

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
    costs_rollouts(k,:) = task.perform_rollout(task,squeeze(theta_eps(k,:,:)),plot_me,color);
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
    cur_theta_new = sum(repmat(weights,1,n_dim).*cur_theta_eps,1);

    % Update the covar matrix
    if (covar_update>0 && covar_update<1)
      % Decaying exploration
      cur_covar_new = covar_update*cur_covar;

    elseif (covar_update>=1)
      % Update with reward-weighed averaging
      eps = cur_theta_eps - repmat(cur_theta,K,1);
      cur_covar_new = (repmat(weights,1,n_dim).*eps)'*eps;
      if (covar_update==1)
        % Only use diagonal
        cur_covar_new = diag(diag(cur_covar_new));
      end
      
      % Avoid numerical issues
      cur_covar_new = real(cur_covar_new);
      
    else
      % Constant exploration
      cur_covar_new = cur_covar;
    end

    if (isempty(covar_bounds))
      % No bounding
      cur_covar_new_bounded = cur_covar_new;
    else
      cur_covar_new_bounded = boundcovar(cur_covar_new,covar_bounds,covar_scales);
    end

    theta_new(i_dof,:) = cur_theta_new;
    covar_new(i_dof,:,:) = cur_covar_new;
    covar_new_bounded(i_dof,:,:) = cur_covar_new_bounded;

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
  learning_history = [learning_history node];

  if (plot_me)
    % Done with plotting of roll-outs
    subplot(n_dofs,4,1:4:n_dofs*4)
    hold off

    plotlearninghistory(learning_history);
    pause
  end
  

  %------------------------------------------------------------------
  % Replace the old with the new. Such is life.
  theta = theta_new;
  covar = covar_new_bounded;

end

% Done with optimizing. Return optimal (?) parameters
theta_opt = theta;



  function [theta_opt learning_history] = testevolutionaryoptimization

    % Get the task (see nest function '[task] = task_min_dist(target)' below)
    target = [0 0];
    task = task_min_dist(target);

    % Initial parameters
    theta_init = [10 10];
    covar_init = [8 0 ; 0 8];

    % Algorithm parameters
    n_updates = 25;
    K = 15;
    
    weighting_method = 2; eliteness = ceil(0.5*K); % CMAES weighting
    weighting_method = 3; eliteness=7; % PI2 weighting
    
    % covar_update = 0;    % Exploration does not change during learning
    covar_update = 0.9;  % Decay exploration during learning
    covar_update = 2;    % Reward-weighted averaging update of covar
    if (covar_update>=1)
      % For covariance matrix updating, a lower bound on the
      % eigenvalues is recommended to avoid premature convergence
      covar_bounds = [0.05 0.1 10]; %#ok<NBRAK> % Lower/upper bounds on covariance matrix
    else
      covar_bounds = []; % No bounds
    end

    % Run optimization
    clf
    [theta_opt learning_history] = evolutionaryoptimization(task,theta_init,covar_init,n_updates,K,eliteness,weighting_method,covar_update,covar_bounds);


    
    
    
    % Here is an example of how to design a task. This one simply returns the
    % distance to the dist.
    function [task] = task_min_dist(target)

      task.name = 'min_dist';
      task.perform_rollout = @perform_rollout_min_dist;
      task.target = target;

      % Now comes the function that does the roll-out and visualization thereof
      function cost = perform_rollout_min_dist(task,theta,plot_me,color)
        % Cost is distance to dist
        cost = sqrt(sum((theta(:)-target(:)).^2));

        % Plot if necessary
        if (nargin>2 && plot_me)
          if (nargin<4)
            color = [0 0 0.6];
          end
          plot([task.target(1) theta(1)],[task.target(2) theta(2)],'-','Color',color)
          plot(theta(1),theta(2),'o','Color',color)
          axis equal
          axis([-10 10 -10 10])
        end

      end

    end

  end

end