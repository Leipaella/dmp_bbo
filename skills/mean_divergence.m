function [splitDecision tree n_splits] = mean_divergence(obj,fig)

%examine the features

%for the moment, we will assume binary features
percept_example = obj.previous_experience.percept;
n_features = size(percept_example,2);
n_dofs = length(obj.distributions);

%figure
figure(10);
clf

for i_split = 1:n_features
  s1 = [];
  s2 = [];
  c1 = [];
  c2 = [];
  
  %now examine all the past samples (end-K+1:end)
  for i_dof = 1:n_dofs
    for sample_ii = 0:obj.K-1
      percept = obj.previous_experience(end - sample_ii).percept;
      if percept(i_split)
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
  
  
  %get the two new distributions
  subplot(n_features,2,(i_split-1)*2 + 1);
  [dist1 summary1] = update_distributions(obj.distributions,s1,c1);
  update_distributions_visualize(summary1,1,s1,1);
  ylabel(strcat('Feature ', num2str(i_split)));
  
  subplot(n_features,2,(i_split-1)*2 + 2);
  [dist2 summary2] = update_distributions(obj.distributions,s2,c2);
  update_distributions_visualize(summary2,1,s2,1);
  
  %get the parent, i.e. general movement of the update
  [pdist psummary] = update_distributions(obj.distributions,cat(2,s1,s2),cat(1,c1,c2));
  
  %we care about whether the two subdistributions are different from
  %eachother or not, particularly if they are moving in different
  %directions around the general movement (parent distribution)
  
  
  
  splitDecision = direction_test(dist1,dist2,pdist);
  tree = [];
  n_splits = 0;
  
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

disp(angle)
if angle > pi/4
  splitDecision = true;
else 
  splitDecision = false;
end

end



