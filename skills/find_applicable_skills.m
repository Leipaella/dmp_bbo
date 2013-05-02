function indices = find_applicable_skills(percept, skill_list)

indices = [];
for ii = length(skill_list):-1:1
  
  conditions = skill_list(ii).conditions; %this is a cell array
  if isempty(conditions)
    answer2 = true;
  else
    
    answer2 = false;
    for jj = 1:length(conditions)
      and_condition = conditions{jj};
      %complete the 'AND'
      answer = true;
      for kk = 1:3:(length(and_condition))
        feature_i = and_condition(kk);
        min_val = and_condition(kk + 1);
        max_val = and_condition(kk + 2);
        if answer && percept(feature_i) >= min_val && percept(feature_i) <= max_val
          answer = true;
        else
          answer = false;
        end
      end %finished going through all the 'AND' operations for this entry
      
      %complete the 'OR'
      if answer2 || answer
        answer2 = true;
      else
        answer2 = false;
      end
      
    end
    
  end
  %now answer2 contains whether the skill is applicable or not.
  
  if(answer2) %if applicable, add to indices list
    indices(end+1) = ii;
  end
end


end