function [splitDecision tree n_splits] = cluster_costs(skill, fig)

figure(fig);
splitDecision = false;
tree = [];
n_splits = 0;

obj = skill;
for ii = 1:length(obj.previous_experience)
  c(ii) = obj.previous_experience(ii).cost(1);
end
color = ['r' 'b' 'k' 'g'];
for n = 1:2
  gaussians{n} = gmdistribution.fit(c',n);
  AIC(n) = gaussians{n}.AIC;
end
[~, nComp] = min(AIC);
gaus = gmdistribution.fit(c', nComp);
hold on;
x = min(c(:)) : 0.01 : max(c(:));
y = pdf(gaussians{nComp},x');
y = y./max(y(:))*obj.i_update;
plot(x,y, color(nComp));

idx = cluster(gaussians{nComp},c');
for ii = 1:nComp
  clusters(ii).x = c(idx ==ii);
  y = 1:obj.i_update;
  clusters(ii).y = y(idx ==ii);
  plot(clusters(ii).x, clusters(ii).y,strcat(color(ii),'o'));
end

if(nComp > 1)
  %means that we need to see if it's time to split!
  %is the percept a good indicator of which cluster label there
  %will be on the cost?
  n_splits = nComp;
  
  for ii = 1:length(obj.previous_experience)
    features(ii,:) = obj.previous_experience(ii).percept;
    labels(ii) = idx(ii);
  end
  
  
  weights = (1:obj.i_update)/obj.i_update;
  tree = classregtree(features,labels,'method','classification','weights',weights);
  %tree = ClassificationTree.fit(features,labels,'crossval','on');
  [cost, ~, ~, best] = test(tree,'crossvalidate',features,labels,'weights',weights);
  tmin = prune(tree,'level',best);
  [cost, ~, ~, best] = test(tree,'crossvalidate',features,labels,'weights',weights);
  if(best && cost(best) < 0.2 && numnodes(tmin)>1)
    splitDecision = true;
    disp(cost(best));
    view(tmin);
    pause;
    tree = tmin;
  else
    splitDecision = false;
  end
  
end

end