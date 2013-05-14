function [weights] = coststoweights(costs,weighting_method,eliteness)
% Convert costs to weights for reward-weighted averaging
%  weighting_method - For reward-weighted averaging
%                       1 - Cross-entropy method weights
%                       2 - CMAES default weights
%                       3 - PI^2 weights
% eliteness         - eliteness parameter (trust the defaults ;-)

if (nargin==0)
  weights = testcoststoweights;
  return
end
if (nargin<2)
  % Default: PI^2 weights
  weighting_method=3;
end
if (nargin<3)
  if (weighting_method==3)
    % Default eliteness parameter 'h' for PI^2
    eliteness = 10;
  else
    % Default elitenss parameter 'K_e' for CEM and CMAES
    eliteness = ceil(0.5*length(costs));
  end
end

S = costs; % Shorthand

if (weighting_method==3)
  % PI^2 weights
  h = eliteness;
  weights = exp(-h*((S-min(S))/(max(S)-min(S))));
else
  weights = zeros(size(costs));
  K_e = eliteness;
  [Ssorted indices] = sort(S,'ascend');
  if (weighting_method==1)
    % Cross-Entropy Method weights
    weights(indices(1:K_e)) = 1;
  elseif (weighting_method==2)
    % CMAES weights
    for ii=1:K_e
      weights(indices(ii)) = log(K_e+1/2)-log(ii);
    end
  else
    warning('Unknown weighting method number %d. Giving all samples zero weight.\n',weighting_method); %#ok<WNTAG>
  end
end

% Normalize weights to sum to 1
weights = weights/sum(weights);


  function [weights] = testcoststoweights
    costs = (0:20)+10;
    weighting_method_labels = {'CEM (K_e=','CMAES (K_e=','PI^2 (h='};
    legend_labels = {};
    figure(1)
    all_weights = [];
    for i_weighting_method=1:3
      for i_eliteness=[5 10]
        all_weights(end+1,:)  = coststoweights(costs,i_weighting_method,i_eliteness);
        legend_labels{end+1} = sprintf('%s%d)',weighting_method_labels{i_weighting_method},i_eliteness);
      end
    end
    clf
    plot(costs,all_weights);
    legend(legend_labels,'Location','NorthEast');
    axis square

    % Return first one. Why not.
    weights = all_weights(1,:);
  end

end