function [sub1 sub2] = copy_and_change(skill_entry,split_feature,split_value)


disp(strcat('Split based on feature ', num2str(split_feature)));
%create a copy
parent = skill_entry.skill;
%make a new skill with the same distribution
subskill1 = Skill(strcat(parent.name,'_sub1'),parent.distributions);
subskill1.learning_history = parent.learning_history;
subskill1.n_figs = parent.n_figs;
subskill1.K = parent.K;
subskill2 = Skill(strcat(parent.name,'_sub2'),parent.distributions);
subskill2.learning_history = parent.learning_history;
subskill2.n_figs = parent.n_figs;
subskill2.K = parent.K;

%create the two conditions
cond1 = {};
cond2 = {};
for jj = 1:length(skill_entry.conditions)
  cond = skill_entry.conditions{jj};
  new_cond_b = [];
  %the new condition if only one value
  if length(split_value) == 1
    new_cond = cat(2, cond, [split_feature -Inf split_value]);
    new_cond2 = cat(2, cond, [split_feature split_value Inf]);
  else %new condition if two split values
    new_cond = cat(2,cond, [split_feature -Inf split_value(1)]);
    new_cond_b = cat(2, cond, [split_feature split_value(2) Inf]);
    new_cond2 = cat(2, cond, [split_feature split_value(1) split_value(2)]);
  end
  cond1{end+1} = new_cond;
  if ~isempty(new_cond_b)
    cond1{end+1} = new_cond_b;
  end
  cond2{end+1} = new_cond2;
end
sub1.conditions = cond1;
sub2.conditions = cond2;
sub1.skill = subskill1;
sub2.skill = subskill2;


end
