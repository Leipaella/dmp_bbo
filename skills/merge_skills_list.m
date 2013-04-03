function skill_list = merge_skills_list(skill_list)
%skill list needs to be a set of conditions and skills
%
%skill_list(1).conditions is an array of conditions, in the form
% [feature_number min_value max_value feature_number min_value max_value]
% [feature_number min_value max_value]
%where all the features in the same row are && and all the features in a
%seperate row are ||
%
%skill_list(1).skill is the skill structure

n_skills = length(skill_list);
indices = [];

%get a list of the indices for converged skills
for i_skill = 1:n_skills
  converged = convergence_test_covar(skill_list(i_skill).skill);
  if converged
    indices(end+1) = i_skill;
  end
end

%compare each skill to each of the others that are converged
for ii = 1:length(indices)
  current_skill = skill_list(indices(ii)).skill;
  for jj = 1:length(indices)
    if ii ~= jj
      compare_skill = skill_list(indices(jj)).skill;
      merge = comparison_test_means(current_skill,compare_skill);
      if merge
        %add an 'OR' case to the current skill and delete compare skill
        disp(strcat('Merge skill ', num2str(indices(ii)), ' with skill ', num2str(indices(jj))));
      end
    end
  end
end



end

function merge = comparison_test_means(skill1, skill2)

%see the probability of choosing skill2's mean from the skill1 distribution
prob = mvnpdf(skill2.mean,skill1.mean,skill1.covar);

if prob > 0.75
  merge = true;
else
  merge = false;
end
  
end


function converged = convergence_test_covar(skill)

%see if the size of the covariances for the last 5 updates were "small"
k = 5;
if length(skill.learning_history) < k
  converged = false;
  return;
end

thresh = [10 pi/12];
converged = true;
for ii = 0:k-1
  past_covar = skill.learning_history(end-ii).distributions.covar;
  test = past_covar <= diag(thresh);
  if ~all(test)
    converged = false;
  end
end


end