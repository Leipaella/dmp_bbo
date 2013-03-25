function [splitDecision tree n_splits] = split_and_merge_by_feature(skill, fig)

figure(fig);
clf;
splitDecision = false;
tree = [];
n_splits = 0;
n_data = 100; %number of data to throw away before using data to do splits 

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
which_features = [];
for i_feature = 1:n_features
    if(var(features(:,i_feature)) > 1e-5)
        which_features(end + 1) = i_feature;
    end
end

for i_feature = which_features
  current_feature = features(:,i_feature);
  
  %determine if the feature is binary or not
  if numel(current_feature(current_feature == 1)) + numel(current_feature(current_feature == 0)) == numel(current_feature)
      bin = 1;
  else
      bin = 0;
  end
  bin = 0;
  if(bin)
      
      subplot(1,n_features,i_feature);
      scatter(current_feature, c);
      
      
      c0 = c(current_feature == 0);
      c1 = c(current_feature == 1);

      n_use = min([length(c0) length(c1)])-1;
      c0 = c0(end-n_use:end);
      c1 = c1(end-n_use:end);
      %now see if they are significantly different;
      splitDecision = ttest(c0,c1);
      if splitDecision
          
          n_splits = 2;
          fake_features = zeros(size(features));
          fake_features(:,i_feature) = current_feature;
          for ii = 1:length(current_feature)
              if current_feature(ii) == 0
                fake_labels(ii,1) = '1';
              else
                  fake_labels(ii,1) = '2';
              end
          end
          tree = classregtree(fake_features,fake_labels,'method','classification');
          [~, ~, ~, best] = test(tree,'crossvalidate',fake_features,fake_labels);
          tmin = prune(tree,'level',best);
          tree = tmin;
          return
      end
      
  else
  
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

      % now, if the gaussians are far enough apart in feature space and cost
      % space and with a small enough variance (i.e. do not take up the whole
      % space) then we want to indicate a split based on this variable. 

      if(nComp == 2)

          %for binary variables, the covar in x is zero, so just need to find
          %in y.
          %solve the intersection iteratively instead of analytically

          y_seperation = pdf(gaus, [gaus.mu(1,1) gaus.mu(2,2)]);
          x_seperation = pdf(gaus, [gaus.mu(2,1) gaus.mu(1,2)]);
          if x_seperation + y_seperation < 1
             % we have reached the threshold, should split!
             splitDecision = 1;
             n_splits = 2;

             %now in order to get a nice matlab tree structure, we have to
             %teach it on fake data to get the structure we want. We can't just
             %assign the nodes directly, how annoying!!

             split = intersect_gaussians(gaus.mu(1,1),gaus.mu(2,1),gaus.Sigma(1,1,1), gaus.Sigma(1,1,2));
             split = split(split > min(current_feature) & split < max(current_feature));
             split = [];
             if isempty(split)
                split = (gaus.mu(1,1) + gaus.mu(2,1))/2;
             end
             fake_features = zeros(size(features));
             fake_features(:,i_feature) = current_feature; %so only have the current feature
             for ii = 1:length(c)
                 if current_feature(ii) > split
                    fake_labels(ii,1) = '1';
                 else
                    fake_labels(ii,1) = '2';
                 end
             end
             tree = classregtree(fake_features,fake_labels,'method','classification');
             [~, ~, ~, best] = test(tree,'crossvalidate',fake_features,fake_labels);
             tmin = prune(tree,'level',best);
             tree = tmin;
             return;
          end
      end
  end
  
%   for n = 1:nComp
%   x = min(current_feature) : 0.01 : max(current_feature);
%   x(2,:) = gaus.mu(n,2);
%   y = pdf(gaus, x');
%   y = (y - min(y))/(max(y)-min(y))*(max(c)-min(c)) + min(c); %normal to make it graph nicely
%   plot(x(1,:),y,color(n));
%   end
end


end