function samples = generate_samples(distributions,n_samples,first_is_mean)

% Input:
%   distributions - distribution from which "samples" were sampled
%                   contains fields, mean, covar, sigma (latter only for CMA-ES)
%   n_samples     - number of samples to take from distribution
%   first_is_mean - set first sample to mean of distribution (default: 1=yes)
%
% Output:
%   samples       - samples from distribution. Size:  n_dofs x n_samples x n_dims

%-------------------------------------------------------------------------------
% Call test function if called without arguments
if (nargin==0)
  samples = test_generate_samples;
  return
end
if (nargin<3)
  first_is_mean = 1;
end

n_dofs = length(distributions);
n_dims  = length(distributions(1).mean);


%-------------------------------------------------------------------------------
% Sample from new distribution
%n_samples = 1000;

samples = zeros(n_dofs,n_samples,n_dims);
for i_dof=1:n_dofs
  mu = distributions(i_dof).mean;
  covar = distributions(i_dof).covar;
  
  
  % Sample from Gaussian for the others
  samples(i_dof,:,:) = mvnrnd(mu,covar,n_samples);
  
%  figure(99)
%  plot(squeeze(samples(i_dof,:,1)),squeeze(samples(i_dof,:,2)),'.k');
  
  if (isequal(diag(diag(covar)),covar))
    warning('Todo: optimize sampling from diagonal covar') %#ok<WNTAG>
 %   samples(i_dof,:,:)
  end

  %plot(squeeze(samples(i_dof,:,1)),squeeze(samples(i_dof,:,2)),'.r');

  if (first_is_mean)
    % Zero exploration in first sample; useful to get performance of current mean
    samples(i_dof,1,:) = mu;
  end

end


% Main function done
%-------------------------------------------------------------------------------



%-------------------------------------------------------------------------------
% Test function
  function  samples = test_generate_samples

    % Make some distributions
    n_dofs = 3;
    n_dims = 2;
    for i_dof=1:n_dofs %#ok<FXUP>
      distributions(i_dof).mean = i_dof*ones(1,n_dims);
      distributions(i_dof).covar = i_dof*[1 0; 0 3];
    end

    % Generate some samples
    n_samples = 100;
    first_is_mean = 1;
    samples = generate_samples(distributions,n_samples,first_is_mean);
    
    % Plotting
    for i_dof=1:n_dofs %#ok<FXUP>
      subplot_handles(i_dof) = subplot(1,n_dofs,i_dof);
      plot(distributions(i_dof).mean(1),distributions(i_dof).mean(2),'ob');
      hold on
      error_ellipse(distributions(i_dof).covar,distributions(i_dof).mean);
      
      cur_samples = squeeze(samples(i_dof,:,:));
      plot(cur_samples(:,1),cur_samples(:,2),'.k');
      hold off
      axis tight
      axis equal
    end
    linkaxes(subplot_handles)
  end

end