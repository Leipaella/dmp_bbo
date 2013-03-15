function [splitDecision tree n_splits] = percept_cost_direct_correlation(skill, fig)



obj = skill;
for ii = 1:length(obj.previous_experience)
  c(ii) = obj.previous_experience(ii).cost(1);
  percept(ii,:) = obj.previous_experience(ii).percept;
end


%find the perception variable that correlates the best
rho = corr(percept,c');
[~, ii] = max(abs(rho));

%plot nicely, with larger dots = more recent
figure(fig);
clf
scatter(percept(:,ii),c,(1:size(percept,1))/size(percept,1)*50,'filled');


%if there is a strong enough correlation, perform splits
if max(abs(rho)) > 0.3
  
  weights = (1:size(percept,1))/size(percept,1);
  p = percept(:,ii);
  [sorted_p ind] = sort(p);
  sorted_c = c(ind);
  sorted_w = weights(ind);
  hold on;
  diff(ii) = 0;
  limit = 0;
  %slide the threshold until there's a biggest variance in mean
  for jj = 20:size(percept,1)-20;
    lower_mean = mean(sorted_c(1:jj));
    upper_mean = mean(sorted_c(jj:end));
    
    %lower_mean = mean(sorted_c(1:jj).*sorted_w(1:jj))/sum(sorted_w(1:jj));
    %upper_mean = mean(sorted_c(jj:end).*sorted_w(jj:end))/sum(sorted_w(jj:end));
    if abs(upper_mean - lower_mean) > diff
      diff = abs(upper_mean - lower_mean);
      limit = jj;
    end
  end
  split_val = sorted_p(limit);
  plot([split_val split_val],[min(c) max(c)],'r');
  c_binary = c;
  c_binary(p<split_val) = 1;
  c_binary(p>=split_val) = 2;
  p_binary = zeros(size(percept));
  p_binary(:,ii) = percept(:,ii);
  tree = classregtree(p_binary,c_binary,'method','classification');
  [cost, ~, ~, best] = test(tree,'crossvalidate',p_binary,c_binary,'weights',weights);
  tree = prune(tree,'level',best);
  view(tree);
  splitDecision = true;
  n_splits = 2;
  pause
else
  splitDecision = false;
  tree = [];
  n_splits = 0;
end
end