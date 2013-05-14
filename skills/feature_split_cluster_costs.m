function [split_decision split_feature split_value] = feature_split_cluster_costs(percepts, costs, p_thresh, fig,test)
%
% For each feature: cluster the costs. See if you can predict which cluster
% a sample will be in based only on its feature. (an extention could be to
% cluster percept-cost space to find combination of features)?
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
%                  and min of that feature, can either be a single value
%                  which then divides the skill by [-Inf, split_value] and
%                  [split_value, Inf] or two values, in which case it is
%                  the min and max of the center segement.


%------------------------------------------------------------------------------
% Initialization of variables


plot_en = 1;
test = 1;
if nargin == 0
  [split_decision split_feature split_value] = test_split_cluster_costs;
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
split_val = cell(1,n_features);
c = costs(:,1);

min_group_fraction = 0.1;
min_group_size = ceil(n_samples*min_group_fraction);

%------------------------------------------------------------------------------
% Run through each feature
for i_feature = 1:n_features
  
  f = percepts(:,i_feature);
  if plot_en
      if ~test, subplot(1,n_features,i_feature); end;
      plot(f,c,'kx');
  end
  
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
    split_val{i_feature} = 0.5;
    
    %------------------------------------------------------------------------------
    % Plot a line splitting binary features, if the threshold is met
    % Write the probability value on the figure as well
    if plot_en
      if ~test, subplot(1,n_features,i_feature); end;
      hold on
      if p_arr(i_feature) < p_thresh
        plot([0.5 0.5],[min(c) max(c)],'g');
      end
      text(0.52,p_arr(i_feature)+0.02, num2str(p_arr(i_feature)),'FontSize',8);
    end
    
  %------------------------------------------------------------------------------
  % Continuous features - need to cluster the costs
  
  else
    %allow up to 3 clusters (for intervals)
    inter_dist = [];
    for n_clusters = 1:3
      [idx, C, sumd] = kmeans(c,n_clusters,'emptyaction','singleton');
      intra_dist(n_clusters) = sum(sumd);
      gaussians{n_clusters} = gmdistribution.fit(c,n_clusters,'Regularize',0.0001);
      AIC(n_clusters) = gaussians{n_clusters}.AIC;
      if n_clusters>1
        ind = combntns(1:n_clusters,2);
        inter_dist(end+1) = min(sqrt(sum(C(ind).^2,2)));
      else
        inter_dist(end+1) = 1;
      end
    end
    
    %find the best number of clusters using the ratio of intra-cluster
    %distances and inter-cluster distances, discussed here:
    % http://www.csse.monash.edu.au/~roset/papers/cal99.pdf
    
    validity = intra_dist./inter_dist;
    
    [~,k] = min(validity);
    
    [~,gmdk] = min(AIC);
    
    [idx, C, sumd] = kmeans(c,k,'emptyaction','singleton');
    idx = gaussians{gmdk}.cluster(c);
    color = ['r';'b';'k'];
    tree = classregtree(f,idx,'method','classification','minparent',ceil(n_samples/10));
    %prune it so as not to overfit the data in a way that won't be visible
    %to us...
    n_levels = max(tree.prunelist);
    tree = prune(tree,max(n_levels - 1,0));
    
    fit = tree.eval(f);
    cm = confusionmat(idx,str2num(cell2mat(fit)));
    
    for kk = 1:max(size(cm))
      %ratio of number_wrong / number_right, want this to be small (zero)
      wrong = (sum(cm(kk,:)) + sum(cm(:,kk)) - 2*cm(kk,kk));
      right = cm(kk,kk);
      err(kk) =  wrong/(right + wrong) ;
    end
    
    [max_correct, i_correct] = min(err);
    if max_correct < 0.05
      %this cluster is predictable!
      disp(['In feature ' num2str(i_feature) ' cluster ' num2str(i_correct) ' is predictable']);
    end
    
    for ii = 1:max(idx)
      hold on;
      if plot_en
        hold on;
        plot(f(idx==ii),c(idx==ii),strcat(color(ii),'x'));
      end
    end
    
        
    %------------------------------------------------------------------------------
    % Plot a line where the limits are in feature space of the best clustering
    
    x = linspace(min(f),max(f),100);
    labels = tree.eval(x');
    matches = str2num(cell2mat(labels)) == i_correct;
    xmin = find(matches,1,'first');
    xmax = find(matches,1,'last');
    if plot_en && max_correct < 0.05 && ~isempty(matches) && k ~= 1
      plot([x(xmin) x(xmin)],[min(c) max(c)],color(i_correct));
      plot([x(xmax) x(xmax)],[min(c) max(c)],color(i_correct));
      text((x(xmax)+x(xmin))/2,(max(c) + min(c))/2, num2str(max_correct),'FontSize',8);
    end
    
    if k ~= 1
      p_arr(i_feature) = min(err);
      split_val{i_feature} = [x(xmin) x(xmax)];
    else
      p_arr(i_feature) = 1;
    end
    
    
  end
end

%------------------------------------------------------------------------------
% Find the best feature to split upon

[pmin imin] = min(p_arr);

%see if the split values are in between min and max feature values
if pmin < p_thresh
  disp('SPLITTING!!');
end

in_range = any(split_val{imin} > min(percepts(:,imin)) & split_val{imin} < max(percepts(:,imin)));



if pmin < p_thresh && in_range
  
  split_decision = true;
  split_feature = imin;
  split_value = split_val{imin};
  
else
  split_decision = false;
  split_feature = 0;
  split_value = [];
end

drawnow;
end






function [split_decision split_feature split_value] = test_split_cluster_costs
%
% Test function - uses fake data to show the effect of clustering or not
% the feature or cost space (or both) and linear ordering of the data on
% feature_split_sliding


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
        [split_decision split_feature split_value] = feature_split_cluster_costs(feature',cost',0.05,1,1);
        
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
