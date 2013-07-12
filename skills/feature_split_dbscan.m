function [split_decision split_feature split_feature_ranges] = feature_split_dbscan(percepts, costs, N, figure_handle)
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

if (nargin<4), figure_handle = 0; end

if nargin == 0
  [split_decision split_feature split_value] = test_split_cluster_costs;
  return;
end
if nargin < 3, p_thresh = 0.1; end
if nargin < 4, plot_en = 0; end
if nargin < 5, test = 0; end

c = costs(:,1);


colors = ['r';'b';'k';'y';'m';'c'];

[class,type]=dbscan(c,N,[]);
if (max(class)>2)
  error('Bummer. Can only deal with 2 classes for now.')
end

if (figure_handle)
  figure(figure_handle)
  clf
  plot(0*c(class==-1),c(class==-1),'x','Color',0.8*[1 1 1]);
  for ii = 1:max(class)
    plot(0*c(class==ii),c(class==ii),strcat(colors(ii),'x'));
    hold on;
  end
  hold off
end

split_decision = false;
split_feature = 0;
split_feature_ranges = [];

if (max(class)<2)
  % Only one class: we cannot split...
  %disp('Cannot cluster on cost. No point in splitting on feature.')
  if (~figure_handle)
    return;
  end
else
  %disp('Can cluster on cost! Trying to split clusters based on features.')
end

n_samples = size(percepts,1);
percepts(:,end+1) = randn(n_samples,1);
percepts(:,end+1) = randn(n_samples,1);
n_features = size(percepts,2);
for i_feature = 1:n_features
  f = percepts(:,i_feature);

  if (max(class)>1)
    min_f1 =  min(f(class==1));
    max_f1 =  max(f(class==1));
    min_f2 =  min(f(class==2));
    max_f2 =  max(f(class==2));
    if (min_f1>max_f2)
      %disp('Found a split!')
      split_value    = mean([min_f1 max_f2]);
      split_decision = true;
      split_feature  = i_feature;
      split_feature_ranges = [split_value Inf; -Inf split_value];
    elseif (min_f2>max_f1)
      %disp('Found a split!')
      split_value    = mean([min_f2 max_f1]);
      split_decision = true;
      split_feature  = i_feature;
      split_feature_ranges = [-Inf split_value; split_value Inf];
    end
  end

  if (figure_handle)
    subplot(1,n_features,i_feature)
    for ii = 1:max(class)
      plot(f(class==ii),c(class==ii),strcat(colors(ii),'x'));
      hold on;
      if (split_decision)
        plot([split_value split_value],[min(c) max(c)],'-g')
      end
    end
    hold off
  end
end
