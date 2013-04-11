function [split_decision split_feature split_value] = feature_split_2D_gaussians(percepts, costs, p_thresh, fig,test)
%
% For each feature: Applies a Gaussian mixture model of either 1 or 2
% components to the 2D feature x cost space (diagonalized covars). If two Gaussians match better,
% uses two Student T-tests to determine if it is seperable
% (significantly different in the feature-axis) and if the feature is
% distinguishable (significantly different in the cost-axis).
% After all features are completed, choose the feature with the lowest
% probability of being a single distribution (i.e. most seperable and distinguishable
% then return the intersection of the two Gaussians as the split value.
%
% Inputs:
%  percepts       -array of percepts with n_samples x n_features, binary or continuous
%  costs          -array of costs with n_samples rows, with the total cost in the first column
%  p_thresh       -maximum probability threshold to determine to split or not (default 0.1)
%  fig            -figure number to display splits. If not given, will not display a plot
%  test           -primarily for running test function, useful in the case
%                  where we want to plot, but want to use whatever filehandle was
%                  previously open (in the case of subplots for ex)
%
% Outputs:
%  split_decision -true or false on whether there should be a split
%  split_feature  -the index of the feature to split upon (which column in percepts)
%  split_value    -the value on which to perform the split (for binary,
%                  will be 0.5, for continuous will be a number between max
%                  and min of that feature


%------------------------------------------------------------------------------
% Initialization of variables
plot_en = 1;
test = 1;
if nargin == 0
  [split_decision split_feature split_value] = test_split_2D_gaussians;
  return;
end
if nargin < 3, p_thresh = 0.1; end
if nargin < 4, plot_en = 0; end
if nargin < 5, test = 0; end


if plot_en && ~test
  figure(fig)
  clf
end

n_features = size(percepts,2);
n_samples = size(percepts,1);
p_arr = zeros(1,n_features);
split_val = zeros(1,n_features);
c = costs(:,1);

%------------------------------------------------------------------------------
% Run through each feature
for i_feature = 1:n_features
  
  f = percepts(:,i_feature);
  
  %------------------------------------------------------------------------------
  % Binary features - know it's seperable, so see if it's distinguishable
  if all(f == 0 | f == 1)
    %seperate the costs into two groups
    c0 = c(f == 0);
    c1 = c(f == 1);
    n0 = length(c0);
    n1 = length(c1);
    if n0 && n1 %be sure not to divide by zero or split cases where there is only 1 value for feature
      %peform Student T-test
      s = sqrt(var(c0)^2/n0 + var(c1)^2/n1);
      t = (mean(c0) - mean(c1)) / s;
      v = n0 + n1 - 2; %degrees of freedom
      %get probability from the t-score (2 tailed test)
      p = 2*tcdf(t,v);
      p_arr(i_feature) = p;
    else
      p_arr(i_feature) = 1; %otherwise, we are sure they're the same distro
    end
    split_val(i_feature) = 0.5;
    
    %------------------------------------------------------------------------------
    % Plot a line splitting binary features, if the threshold is met
    % Write the probability value on the figure as well
    if plot_en
      if ~test, subplot(1,n_features,i_feature); end;
      plot(f,c,'kx');
      hold on
      if p_arr(i_feature) < p_thresh
        plot([0.5 0.5],[min(c) max(c)],'g');
      end
      text(0.52,p_arr(i_feature)+0.02, num2str(p_arr(i_feature)),'FontSize',8);
    end
    
  %------------------------------------------------------------------------------
  % Continuous features - See if seperable and distinguishable 
  % make sure the variance is not zero (or else mixture model won't work)
  elseif var(c) ~= 0 && var(f) ~= 0             
    %fit a Gaussian mixture model to the data
    for n_gaus = 1:2
      gaussians{n_gaus} = gmdistribution.fit([f c],n_gaus,'Regularize',0.001,'CovType','diagonal');
      AIC(n_gaus) = gaussians{n_gaus}.AIC;
    end
    [~, nComp] = min(AIC);
    gaus = gaussians{nComp};
    if nComp == 2
      
      labels = cluster(gaus,[f c]);
      f1 = f(labels == 1);
      f2 = f(labels == 2);
      c1 = c(labels == 1);
      c2 = c(labels == 2);
      n1 = length(c1);
      n2 = length(c2);
      
      %apply a paired Student T-test on the feature gaussians to see if it's
      %seperable
      s = sqrt(var(f1)^2/n1 + var(f2)^2/n2);
      t = (mean(f1) - mean(f2)) / s;
      if t>0, t = -t; end
      v = n1 + n2 - 2; %degrees of freedom
      pS = 2*tcdf(t,v); %two tailed test
      
      %apply a paired Student T-test on the cost gaussians to see if it's
      %distinguishable
      s = sqrt(var(c1)^2/n1 + var(c2)^2/n2);
      t = (mean(c1) - mean(c2)) / s;
      v = n1 + n2 - 2; %degrees of freedom
      if t>0, t = -t; end
      pD = 2*tcdf(t,v); %two tailed test
      
      %find intersection value of the two 2D gaussians
      %split_val(i_feature) = fzero(@(x) normpdf(x, mean(f1),var(f1)) - normpdf(x,mean(f2),var(f2)),[min(f) max(f)]);
      split_val(i_feature) = (mean(f1) + mean(f2))/2;
      
      %want to minimize the sum
      p_arr(i_feature) = pS + pD;
      
    else
      p_arr(i_feature) = 1; %if only one Gaussian, know it will be the same distribution
    end
    
    %------------------------------------------------------------------------------
    % Plot a line seperating the Gaussian features, if the threshold is met
    % Write the probability value as well
    if plot_en
      if ~test, subplot(1,n_features,i_feature); end;
      plot(f,c,'kx');
      hold on;
      %ezcontour(@(x,y)pdf(gaus,[x y]),[min(f) max(f)],[min(c) max(c)]);
      if p_arr(i_feature) < p_thresh
        plot([split_val(i_feature) split_val(i_feature)],[min(c) max(c)],'g');
      end
      text((max(f)+min(f))/2,(max(c)+min(c))/2, num2str(p_arr(i_feature)),'FontSize',8);
      drawnow;
    end
    
    
  end
end

%------------------------------------------------------------------------------
% Find the best feature to split upon

[pmin imin] = min(p_arr);

if pmin < p_thresh
  split_decision = true;
  split_feature = imin;
  split_value = split_val(imin);
else
  split_decision = false;
  split_feature = [];
  split_value = [];
end


end






function [split_decision split_feature split_value] = test_split_2D_gaussians
%
% Test function - uses fake data to show the effect of clustering or not
% the feature or cost space (or both) and linear ordering of the data on
% feature_split_2D_gaussians


N = 8; % Should be even

% cost data points
c = [...
  linspace(0,1,N);                               % Equidistant
  [ linspace(0,0.2,N/2) linspace(0.8,1.0,N/2) ]; % Two clusters (two tasks)
  linspace(0.5,0.5,N);                           % One cluster (one task)
  ];
c_labels = {'c-clus=no','c-clus=yes','c-clus=one',};

% feature data points
f = [...
  linspace(0,1,N);                               % Equidistant
  [ linspace(0,0.2,N/2) linspace(0.8,1.0,N/2) ]; % Two clusters
  [ zeros(1,N/2) ones(1,N/2) ];                  % Binary feature
  ];
f_labels = {'f-clus=no','f-clus=yes','f-clus=bin'};

% feature relevance (orders cost values to be clustered with features or not)
f_rel = [...
  [ 1:2:N 2:2:N];
  1:N;
  ];
f_rel_labels = {'f-rel=no','f-rel=yes'};


clf
for ordering_within_cluster=1:2 % see comment below
  figure(ordering_within_cluster)
  count = 1;
  
  for c_i = 1:size(c,1)
    for f_i = 1:size(f,1)
      for f_rel_i = 1:size(f_rel,1)
        
        ordering = f_rel(f_rel_i,:);
        if (ordering_within_cluster==2)
          % If the ordering was 1 2 3 4 5 6 7 8 before
          % it will be          4 3 2 1 8 7 6 5 after.
          % This matters only for the special case when
          % c-clus=no, f-clus=no, f-rel=yes
          ordering = ordering([N/2:-1:1 N:-1:(N/2+1)]);
        end
        
        
        % Default marker color (for irrelevant features)
        color = [0.8 0 0];
        if (strcmp(f_rel_labels{f_rel_i},'f-rel=yes'))
          if (strcmp(c_labels{c_i},'c-clus=one'))
            % If there is only one cost cluster, there is only one task. Therefore,
            % no feature could be relevant to splitting, because there is nothing
            % to split. Change plotting color to indicate this
            color = [0.8 0.8 0.8];
          else
            % Indicate that a feature is relevant by making it green
            color = [0 0.8 0];
          end
        end
        
        subplot(size(c,1),size(f,1)*size(f_rel,1),count); count = count + 1;
        
        feature = f(f_i,:);
        cost = c(c_i,ordering);
        [split_decision split_feature split_value] = feature_split_2D_gaussians(feature',cost',0.05,1,1);
        
        hold on
        plot(f(f_i,:),c(c_i,ordering),'o','MarkerEdgeColor','none','MarkerFaceColor',color)
        plot(f(f_i,:),-0.2*ones(1,N),'o','MarkerEdgeColor','none','MarkerFaceColor',color)
        plot(-0.2*ones(1,N),c(c_i,:),'o','MarkerEdgeColor','none','MarkerFaceColor',color)
        hold off
        axis square
        axis([-0.2 1.2 -0.2 1.2])
        title([c_labels{c_i} ' ' f_labels{f_i} ' ' f_rel_labels{f_rel_i} ])
      end
    end
  end
end



end
