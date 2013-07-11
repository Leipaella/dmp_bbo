function [task] = task_viapoint(viapoint,viapoint_time_ratio)
if (nargin<1), viapoint  = [0.4 0.7]; end
if (nargin<2), viapoint_time_ratio = 0.5; end

task.name = 'viapoint';

task.viapoint = viapoint;
task.viapoint_time_ratio = viapoint_time_ratio;

task.cost_function= @cost_function_viapoint;
task.observation_function= @observation_function_viapoint;


  function costs = cost_function_viapoint(task,cost_vars)
    
    [n_rollouts n_time_steps n_cost_vars ] = size(cost_vars); %#ok<NASGU>
    viapoint_time_step = round(task.viapoint_time_ratio*n_time_steps);
    
    for k=1:n_rollouts
      ys   = squeeze(cost_vars(k,:,1:3:end));
      ydds = squeeze(cost_vars(k,:,3:3:end));

      dist_to_viapoint = sqrt(sum((ys(viapoint_time_step,:)-viapoint).^2));
      costs(k,2) = dist_to_viapoint;

      % Cost due to acceleration
      sum_ydd = sum((sum(ydds.^2,2)));
      costs(k,3) = sum_ydd/10000;
      costs(k,3) = costs(k,3)/50; %added to make acceleration less important

      % Total cost is the sum of all the subcomponent costs
      costs(k,1) = sum(costs(k,2:end));
    end
  end

  function observation = observation_function_viapoint(task,N,min_values,max_values,plot_me)
    n_dim = length(task.viapoint);
    if (n_dim~=2)
      error('Sorry. observation_function_viapoint only works for n_dim==2 (but it is %d)',n_dim)
    end
    if (nargin<2), N = 20; end
    if (nargin<3), min_values = zeros(1,n_dim); end
    if (nargin<4), max_values = ones(1,n_dim); end
    if (nargin<5), plot_me = 0; end

    % Scale viapoint in normalized space [0-1]
    scaled_viapoint = (task.viapoint-min_values)./(max_values-min_values);
    % Generate X/Y grid in normalized space
    [X Y] = meshgrid(linspace(0,1,N),linspace(0,1,N));
    % Get value in multi-variate normal distribution
    Z = mvnpdf([ X(:) Y(:)],scaled_viapoint,0.001*eye(n_dim));
    % Make an NxN image of this.
    image = reshape(Z,N,N);
    
    if (plot_me)
      mesh(image)
      axis square
      axis tight
    end
    
    observation = image;
    
    
  end


end

