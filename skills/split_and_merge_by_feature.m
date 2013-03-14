function [splitDecision tree n_splits] = split_and_merge_by_feature(skill, fig)

figure(fig);
splitDecision = false;
tree = [];
n_splits = 0;
n_data = 100; 

obj = skill;
%put the cost function into c
%put the percepts into features

if(length(obj.previous_experience) > n_data)
  start = length(obj.previous_experience) - n_data;
else
  start = 1;
end


for ii = start:length(obj.previous_experience)
  c(ii - start + 1) = obj.previous_experience(ii).cost(1);
  features(ii-start+1,:) = obj.previous_experience(ii).percept;
end



color = ['r' 'b' 'k' 'g'];

%go through each feature. See how many Gaussians best fit the feature v.
%cost
n_features = length(obj.previous_experience(1).percept);

for i_feature = 1:n_features
  current_feature = features(:,i_feature);
  %try with 1 or 2 gaussians
  for n_gaus = 1:2
    gaussians{n_gaus} = gmdistribution.fit([current_feature c'],n_gaus,'Regularize',0.00001);
    AIC(n_gaus) = gaussians{n_gaus}.AIC;
  end
  
  [~, nComp] = min(AIC);
  gaus = gaussians{nComp};
  subplot(1,n_features,i_feature);
  hold on;
  scatter(current_feature,c','rx');
  h = ezcontour(@(x,y)pdf(gaus,[x y]),[min(current_feature) max(current_feature)],[min(c) max(c)]);
  
%   for n = 1:nComp
%   x = min(current_feature) : 0.01 : max(current_feature);
%   x(2,:) = gaus.mu(n,2);
%   y = pdf(gaus, x');
%   y = (y - min(y))/(max(y)-min(y))*(max(c)-min(c)) + min(c); %normal to make it graph nicely
%   plot(x(1,:),y,color(n));
%   end
end

pause

end