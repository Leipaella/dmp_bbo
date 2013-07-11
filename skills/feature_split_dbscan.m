function [split_decision split_feature split_value] = feature_split_dbscan(percepts, costs, p_thresh, fig,test)
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

c = costs(:,1);


colors = ['r';'b';'k';'y';'m';'c'];

[class,type]=dbscan(c,10,[]);
if (max(class)>2)
  error('Bummer. Can only deal with 2 classes for now.')
end
figure(12)
clf
plot(0*c(class==-1),c(class==-1),'x','Color',0.8*[1 1 1]);
for ii = 1:max(class)
  plot(0*c(class==ii),c(class==ii),strcat(colors(ii),'x'));
  hold on;
end
hold off

split_decision = false;
split_feature = 0;
split_value = 0;

if (max(class)==1)
  % Only one class: we cannot split...
  disp('Cannot cluster on cost. No point in splitting on feature.')
  %return;  
else
  disp('Can cluster on cost! Trying to split clusters based on features.')
end

n_samples = size(percepts,1);
percepts(:,end+1) = randn(n_samples,1);
percepts(:,end+1) = randn(n_samples,1);
n_features = size(percepts,2);
for i_feature = 1:n_features
  subplot(1,n_features,i_feature)
  f = percepts(:,i_feature);
  f_between = [];

  if (max(class)>1)
    min_f1 =  min(f(class==1));
    max_f1 =  max(f(class==1));
    min_f2 =  min(f(class==2));
    max_f2 =  max(f(class==2));
    if (min_f1>max_f2)
      f_between = mean([min_f1 max_f2]);
    elseif (min_f2>max_f1)
      f_between = mean([min_f2 max_f1]);
      split_decision= true;
    end
    if (~isempty(f_between))
      % Found a split!
      disp('Found a split!')
      split_value = f_between;
      split_decision = true;
      split_feature  = i_feature;
    end
  end
  
  for ii = 1:max(class)
    plot(f(class==ii),c(class==ii),strcat(colors(ii),'x'));
    hold on;
    if (~isempty(f_between))
      plot([f_between f_between],[min(c) max(c)],'-g')
    end
  end
  hold off
end

pause
