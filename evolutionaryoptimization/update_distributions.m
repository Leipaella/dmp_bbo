function [distributions_new summary] = update_distributions(distributions,samples,costs,update_parameters)
% Input:
%   distributions - distribution from which "samples" were sampled
%                   mean, covar, sigma, evolution paths (last two only for CMA-ES)
%   samples       - samples from above distribution. Size:  n_dofs x n_samples x n_dims
%   costs         - costs for each sample: 1 x n_samples
%   update_parameters - parameters for updating (usually constant during optimization)
%              weighting_method   - PI-BB, CMA-ES
%              eliteness          - h (PI-BB), K_e (CMA-ES, CEM)
%              covar_update       - None, Decay, PI-BB, CMA-ES
%              covar_full         - 1: full covar update
%                                   0: diagonal only
%              covar_full         - 1: full covar update
%              covar_learing_rate - [0-1] (0 do nothing, 1 disregard previous)
%
% Output:
%   distributions_new - updated distributions
%   summary           - structure with summary of this update

%-------------------------------------------------------------------------------
% Call test function if called without arguments
if (nargin==0)
  [distributions_new summary] = test_update_distributions;
  return
end

n_dofs = length(distributions);
n_dims  = length(distributions(1).mean);


%-------------------------------------------------------------------------------
% Set defaults
if (nargin<4)
  update_parameters.weighting_method    = 'PI-BB';
  update_parameters.eliteness           =      10;
  update_parameters.covar_update        = 'PI-BB';
  update_parameters.covar_full          =       0;
  update_parameters.covar_learning_rate =       1;
  update_parameters.covar_bounds        =      [];
  update_parameters.covar_scales        =       1;
end

if (ndims(samples)==2)
  % This function assumes samples is of size n_dofs x n_samples x n_dim
  % If is is of size n_samples x n_dim, add n_dofs=1 dimension at the front
  samples = shiftdim(samples,-1);
end

% How many samples do we need to take?
n_samples = size(samples,2);

%-------------------------------------------------------------------------------
% First, map the costs to the weights
if (strcmp(update_parameters.weighting_method,'PI-BB'))
  % PI^2 style weighting: continuous, cost exponention
  h = update_parameters.eliteness; % In PI^2, eliteness parameter is known as "h"
  weights = exp(-h*((costs-min(costs))/(max(costs)-min(costs))));

elseif (strcmp(update_parameters.weighting_method,'CMA-ES'))
  % CMA-ES style weights: rank-based, uses defaults
  mu = update_parameters.eliteness; % In CMA-ES, eliteness parameter is known as "mu"
  [Ssorted indices] = sort(costs,'ascend');
  weights = zeros(size(costs));
  for ii=1:mu
    weights(indices(ii)) = log(mu+1/2)-log(ii);
  end

else
  warning('Unknown weighting method number %s. Setting to "PI-BB".\n',update_parameters.weighting_method); %#ok<WNTAG>
  % Call recursively with fixed parameter
  update_parameters.weighting_method = 'PI-BB';
  [ samples_new distributions_new ] = update_and_sample(samples,costs,distribution,update_parameters,n_samples);
  return;
end

% Normalize weights
weights = weights/sum(weights);


%-------------------------------------------------------------------------------
% Second, compute new mean
distributions_new = distributions;
for i_dof=1:n_dofs
  % Update with reward-weighed averaging
  distributions_new(i_dof).mean = sum(repmat(weights,1,n_dims).*squeeze(samples(i_dof,:,:)),1);
end

%-------------------------------------------------------------------------------
% Third, compute new covariance matrix
for i_dof=1:n_dofs
  covar = distributions_new(i_dof).covar;

  if (strcmp(update_parameters.covar_update,'Decay'))
    % Decaying exploration
    covar_new = update_parameters.covar_decay*covar;

  elseif (strcmp(update_parameters.covar_update,'PI-BB'))
    % Update with reward-weighed averaging
    eps = squeeze(samples(i_dof,:,:)) - repmat(distributions(i_dof).mean,n_samples,1);
    covar_new = (repmat(weights,1,n_dims).*eps)'*eps;
    if (~update_parameters.covar_full)
      % Only use diagonal
      covar_new = diag(diag(covar_new));
    end

    % Avoid numerical issues
    covar_new = real(covar_new);

    % Apply low pass filter
    rate = update_parameters.covar_learning_rate;
    covar_new = (1-rate)*covar + rate*covar_new;

  elseif (strcmp(update_parameters.covar_update,'None'))
    % Constant exploration
    % Do nothing: covars were already copied into distributions_new above
    covar_new = covar;
  else
    if (i_dof==1) % Warn only on the first iteration.
      if (strcmp(update_parameters.covar_update,'CMA-ES'))
        warning('CMA-ES covariance matrix updating not implemented yet') %#ok<WNTAG>
      else
        warning('Unknown covariance matrix update method %s. Not updatinf covariance matrix.\n',update_parameters.covar_update); %#ok<WNTAG>
      end
    end
    covar_new = covar;
  end

  if (isempty(update_parameters.covar_bounds))
    % No bounding
    covar_new_bounded = covar_new;
  else
    covar_new_bounded = boundcovar(covar_new,update_parameters.covar_bounds,update_parameters.covar_scales);
  end

  distributions_new(i_dof).covar = covar_new_bounded;
end

%-------------------------------------------------------------------------------
% Bookkeeping: put relevant information in a summary
summary.distributions = distributions;
summary.samples = samples;
summary.costs = costs;
summary.weights = weights;
summary.distributions_new = distributions_new;
  
% Main function done
%-------------------------------------------------------------------------------





%-------------------------------------------------------------------------------
% Test function
  function  [distributions_new summary ] = test_update_distributions
    % Make a distribution
    n_dims = 2;
    center = 2;
    distributions.mean = center*ones(1,n_dims);
    distributions.covar = eye(n_dims);

    % Generate some samples
    n_samples = 20;
    first_is_mean = 1;
    samples = generate_samples(distributions,n_samples,first_is_mean);
    costs = sqrt(sum(squeeze(samples(1,:,:)).^2,2));

    % Set some update parameters
    update_parameters.weighting_method    = 'PI-BB';
    update_parameters.eliteness           =       7;
    update_parameters.covar_update        = 'PI-BB';
    update_parameters.covar_full          =       0;
    update_parameters.covar_learning_rate =       1;
    update_parameters.covar_bounds        =      [];
    update_parameters.covar_scales        =       1;
    update_parameters.covar_decay         =     0.7;

    % Do updates for different update methods
    covar_updates = {'PI-BB','PI-BB','Decay','None'};
    for ff=1:4
      update_parameters.covar_update = covar_updates{ff};
      figure_title = covar_updates{ff};
      if (ff==2)
        update_parameters.covar_full = 1;
        figure_title = [ figure_title ' (diagonal only)'];
      end

      [ distributions_new summary ] = update_distributions(distributions,samples,costs,update_parameters);

      figure(ff)      
      highlight=1;
      plot_samples=1;
      update_distributions_visualize(summary,highlight,plot_samples);
      axis equal
      axis([-2 5 -2 5]);
      title(figure_title)
    end
  end

end