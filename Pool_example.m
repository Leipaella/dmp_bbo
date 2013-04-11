% Randomly chooses to give a task that will either be with an enemy ball
% behind the goal, or very close to the goal.



close all;

%n_dims = 3;
n_dofs = 1; %can control starting x location, angle, and force.


%get the initial values somewhere in the ballpark
%sx power angle
%distributions(1).mean = [0 5000 0];
%distributions(1).covar = diag([5 1000^2 1000^2]);

n_dims = 2;
distributions(1).mean = [45 pi/2];
distributions(1).covar = diag([5^2 (pi/8)^2]);




obj = Skill('Pool',distributions);
obj.rollout_buffer = [];
obj.i_update = 0;
obj.n_figs = 3;
obj.idx = 0;
count = 0;
goal = [25 75];

%skill list
skill_list(1).skill = obj;
skill_list(1).conditions = {[]};



while count < 1000
  
  %generation 1 happy ball and 1 enemy ball
  %   x = ceil(50*rand([1 2]));
  %   y = ceil(100*rand([1 2]));
  %   teams = [1 2];
  %   balls.x = x;
  %   balls.y = y;
  %   balls.teams = teams;
  %
  p = randperm(2);
  [tasks percepts] = generate_unique_tasks(goal);
  
  
  
  
  %percept can be their polar coordinates from the goal for example. and
  %which team
  %r = sqrt((x - goal(1)).^2 + (y - goal(2)).^2);
  %t = atan2((y - goal(2)),(x - goal(1)));
  %percept(1:2) = r;
  %percept(3:4) = t;
  %percept(5:6) = teams;
  
  %make the percept simple
  %percept = [];
  %percept(1) = p(1) - 1;
  
  %task = task_pool(goal,balls);
  
  task = tasks(p(1));
  percept = percepts(p(1),:);
  task_solver = task_pool_solver;
  
  for ii = length(skill_list):-1:1
    
    %
    %see if skill holds - basically precondition test
    %
    
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
    
    if(answer2) %if applicable, perform skill
      skill_list(ii).skill = solve_task_instance(skill_list(ii).skill,task,task_solver,percept);
    end
  end
  
  %
  %now see if splitting is needed.
  %
  
  if mod(count,50) == 0
    
    n_skills = length(skill_list);
    for ii = 1:n_skills;
      [split_decision split_feature split_value] = mean_divergence(skill_list(ii).skill);
      %using only binary features
      if(split_decision)
        
        disp(strcat('Split based on feature ', num2str(split_feature)));
        %create a copy
        new_skill = skill_list(ii).skill;
        new_skill.idx = length(skill_list) + 1;
        %clear previous experience so it won't keep splitting
        new_skill.previous_experience(1:end) = [];
        skill_list(ii).skill.previous_experience(1:end) = [];
        %create the two conditions
        for jj = 1:length(skill_list(ii).conditions)
          cond = skill_list(ii).conditions{jj};
          new_cond = cat(2, cond, [split_feature 0 split_value]);
          new_cond2 = cat(2, cond, [split_feature split_value 1]);
          cond1{jj} = new_cond;
          cond2{jj} = new_cond2;
        end
        skill_list(ii).conditions = cond1;
        skill_list(end+1).skill = new_skill;
        skill_list(end).conditions = cond2;
      end
    end
    
  end
  %
  %now see if merging is needed.
  %
  if mod(count,50) == 25
    %skill_list = merge_skills_list(skill_list);
  end
  
  %obj = obj.solve_task_instance(task,task_solver,percept);
  count = count+1;
  
  
  %percept is the location of the enemy ball in [x y], whether the enemy ball is
  %in front of (1) or behind (0) the goal, whether the enemy ball is to the
  %left or right of the goal
  %
  % enemy position [x y] discretized
  % enemy in front/behind = 0/1
  % enemy left/right = 0/1
  
  %start with 2 cases, one far away and behind, and one in front of and
  %close
  %choice = randi(2);
  %switch choice
  %    case 1, enemy = goal + [0 10];
  %    case 2, enemy = goal + [0 -10];
  %case 3, enemy = goal + [10 10];
  %case 4, enemy = goal + [10 -10];
  %end
  %
  %   %noise = rand(1,2)*3;
  %   %enemy = enemy + noise;
  %   %percept(1:2) = enemy;
  %
  %   %front/back
  %   if(enemy(2) <= goal(2))
  %       percept(1) = 0; %in front of the goal
  %   else
  %       percept(1) = 1; %behind the goal
  %   end
  %
  %   %left/right
  %   if(enemy(1) <= goal(1))
  %       percept(2) = 0;
  %   else
  %       percept(2) = 1;
  %   end
  %
  %   task = task_pool(goal,balls);
  %   task_solver = task_pool_solver;
  %
  %   obj = obj.solve_task_instance(task,task_solver,percept);
  %   count = count+1;
  
  
end



timestr = datestr(clock);
timestr(timestr == ' ') = '_';
timestr(timestr == ':') = '-';

save(timestr,'obj','percepts','tasks','task_solver');
