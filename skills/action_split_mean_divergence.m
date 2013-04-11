function [splitDecision split_feature split_value] = action_split_mean_divergence(obj,fig)

if nargin == 0
  test_mean_divergence();
  return;
end

% if mod(length(obj.previous_experience),obj.K-1) ~= 0 && ~isempty(obj.previous_experience)
%   splitDecision = false;
%   split_feature = [];
%   split_value = [];
%   return;
% end


%examine the features

%for the moment, we will assume binary features
percept_example = obj.previous_experience.percept;
n_features = size(percept_example,2);
n_dofs = length(obj.distributions);
split_value = 0.5;

%figure;
figure(10);
clf

for i_feature = 1:n_features
  s1 = [];
  s2 = [];
  c1 = [];
  c2 = [];
  
  %now examine all the past samples (end-K+1:end)
  for i_dof = 1:n_dofs
    for sample_ii = 0:min(obj.K-2,length(obj.previous_experience)-1);
      percept = obj.previous_experience(end - sample_ii).percept;
      if percept(i_feature)
        %belongs to new_obj_1
        s1(i_dof,end+1,:) = obj.previous_experience(end-sample_ii).sample;
        c1(end+1,:) = obj.previous_experience(end-sample_ii).cost;
      else
        %belongs to new_obj_2
        s2(i_dof,end+1,:) = obj.previous_experience(end-sample_ii).sample;
        c2(end+1,:) = obj.previous_experience(end-sample_ii).cost;
      end
    end
  end
  
  if isempty(c2) || isempty(c1)
    splitDecision = false;
    split_feature = [];
    split_value = [];
    return;
  end
  
  %get the two new distributions
  subplot(n_features,2,(i_feature-1)*2 + 1);
  [dist1 summary1] = update_distributions(obj.distributions,s1,c1);
  update_distributions_visualize(summary1,1,s1,1);
  ylabel(strcat('Feature ', num2str(i_feature)));
  
  subplot(n_features,2,(i_feature-1)*2 + 2);
  [dist2 summary2] = update_distributions(obj.distributions,s2,c2);
  update_distributions_visualize(summary2,1,s2,1);
  
  %get the parent, i.e. general movement of the update
  [pdist psummary] = update_distributions(obj.distributions,cat(2,s1,s2),cat(1,c1,c2));
  
  %we care about whether the two subdistributions are different from
  %eachother or not, particularly if they are moving in different
  %directions around the general movement (parent distribution)
  n1 = length(c1);
  n2 = length(c2);
  
  T = n1*n2/(n1+n2)*(dist1.mean - dist2.mean)*inv(pdist.covar)*(dist1.mean - dist2.mean)';
  scores(i_feature) = T;
  
  %splitDecision = direction_test(dist1,dist2,pdist);
  %split_feature = i_feature;
  
end

[max_T best_feature] = max(scores);

if(max_T > 30) %we should split
  splitDecision = true;
  split_feature = best_feature;
  split_value = 0.5; %since binary, if continuous this would be a value
else
  splitDecision = false;
  split_feature = [];
  split_value = [];
end

%have all the subplots have equal axes
axesHandles = get(gcf,'children');
linkaxes(axesHandles);



end

function splitDecision = direction_test(dist1, dist2, refdist)

A = dist1.mean - refdist.mean;
B = dist2.mean - refdist.mean;

angle = acos( sum(A(:).*B(:))/( sqrt(sum(A.^2))*sqrt(sum(B.^2)) ) );


if(angle > pi)
  angle = 2*pi - pi;
end

%disp(angle)
if angle > pi/4
  splitDecision = true;
else
  splitDecision = false;
end

end


function test_mean_divergence()

%create a cost distribution where the two cost functions are distances to
%nearby points, the x and y are the 2-D action

figure;

%pick samples
mu = [0 0];
covar = diag([1 1]);
thetas = mvnrnd(mu,covar,100);

thetas1 = thetas(1:end/2,:);
thetas2 = thetas(end/2:end,:);

%scatter(thetas1(:,1),thetas1(:,2),'bx');
%hold on;
%plot(thetas2(:,1),thetas2(:,2),'rx');

goal1 = [2 2];
goal2 = [-2 2];

costs1 = sum(( thetas1-repmat(goal1,[size(thetas1,1) 1]) ).^2,2);
costs2 = sum(( thetas2-repmat(goal2,[size(thetas2,1) 1]) ).^2,2);

percept1 = randi(2,[size(costs1,1) 3]) - 1;
percept1(:,4) = 0;

percept2 = randi(2,[size(costs2,1) 3]) - 1;
percept2(:,4) = 1;

distribution.mean = mu;
distribution.covar = covar;

thetas = [thetas1; thetas2];
percept = [percept1; percept2];
costs = [costs1; costs2];


n_features = size(percept,2);

for i_feature = 1:n_features
  thetas1 = [];
  thetas2 = [];
  costs1 = [];
  costs2 = [];
  
  for ii = 1:size(percept,1)
    switch(percept(ii,i_feature))
      case 0
        thetas1(end+1,:) = thetas(ii,:);
        costs1(end+1) = costs(ii);
      case 1
        thetas2(end+1,:) = thetas(ii,:);
        costs2(end+1) = costs(ii);
    end
  end
  
  
  [dist1 sum1] = update_distributions(distribution,thetas1,costs1');
  [dist2 sum2] = update_distributions(distribution,thetas2,costs2');
  
  subplot(n_features,2,(i_feature-1)*2 + 1,'replace');
  update_distributions_visualize(sum1,1,1,1);
  axis equal
  subplot(n_features,2,(i_feature-1)*2 + 2,'replace');
  update_distributions_visualize(sum2,1,1,1);
  axis equal
  axesHandles = get(gcf,'children');
  linkaxes(axesHandles);
  
  
  
  
  n1 = length(costs1);
  n2 = length(costs2);
  T = n1*n2/(n1+n2)*(dist1.mean - dist2.mean)*inv(covar)*(dist1.mean - dist2.mean)';
  scores(i_feature) = T;
  disp(T);
  
  if T > 30
    splitDecision = true;
  else
    splitDecision = false;
  end
  
end


end


