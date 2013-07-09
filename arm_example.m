close all;
clearvars;
fh = figure(10);
n_skills_disp = 4;
goal_learning = false;

if goal_learning
  n_dofs = 12; %DMP working in 6-D space, and x,y,z,alpha,beta,gamma of the goal
else
  n_dofs = 6; %DMP working in 6-D space, goal given
  g = [5 5 -5 pi/2 pi/2 pi/2];%ones([1 6])*pi/2;
end
n_dims = 3; %number of basis functions



p_thresh = 0.15;

%get the initial values somewhere in the ballpark
%sx power angle
mean_init = zeros([1 n_dims]);
covar_init = 5*eye(size(mean_init,2));
for i_dof = 1:n_dofs
  distributions(i_dof).mean = mean_init;
  distributions(i_dof).covar = covar_init;
end

obj = Skill('Arm',distributions);
obj.rollout_buffer = [];
obj.i_update = 0;
obj.n_figs = 3;
obj.idx = 0;
count = 0;
goal = [25 75];

%skill list
skill_list(1).conditions = {[]};
skill_list(1).skill = obj;
skill_list(1).history = [];

[tasks percepts n_tasks] = generate_shape_tasks;

disp_n_skills = 4;
 
while count < 5000
  

  %--------------------------------------------------------------------------
  % Generate a task and percept
  
  p = randperm(n_tasks);
  task = tasks(p(1));
  percept = percepts(p(1),:);
  y0 = [0 0 0 0 0 0];
  evaluation_external_program = true;
  if goal_learning
    task_solver = task_arm_path_solver(y0,evaluation_external_program);
  else
    task_solver = task_arm_path_solver(y0,evaluation_external_program,g);
  end
  
  
  %--------------------------------------------------------------------------
  %see if skill holds - basically precondition test
  %
  indices = find_applicable_skills(percept, skill_list);
  
  %--------------------------------------------------------------------------
  %execute the first applicable skill
  %
  first = min(indices);
  if isempty(first)
    error('The percept does not meet any conditions in the skill list');
  end
  skill_list(first).skill = solve_task_instance(skill_list(first).skill,task,task_solver,percept);
    
  
  
  %--------------------------------------------------------------------------
  % loop through the skill list
  %
   
  n_skills = length(skill_list);
  for ii = 1:n_skills;
    
    %--------------------------------------------------------------------------
    % see if the buffer has 1 entry - indicates the distribution was just
    % updated, so can update the left plot.
    %
    
    c_skill = skill_list(ii).skill;
    if length(c_skill.rollout_buffer) == 1
      figure(fh);
      rows = disp_n_skills;
      cols = 2*length(percept);
      t = meshgrid(1:cols:rows*cols,1:cols/2)'-1 + meshgrid(1:cols/2,1:rows);
      subplot(rows,cols,t(:));
      hold on;
      n_dims  = length(c_skill.distributions.mean);
      plot_n_dim = min(n_dims,3);
      for hist = 1:length(skill_list(ii).history)
        theta = skill_list(ii).history(hist).theta;
        covar = skill_list(ii).history(hist).covar;
        h_covar = error_ellipse(real(squeeze(covar(1:plot_n_dim,1:plot_n_dim))),theta(1:plot_n_dim));
        set(h_covar,'Color',0.8*ones(1,3),'LineWidth',1);
      end
      covar = c_skill.distributions.covar;
      theta = c_skill.distributions.mean;
      h_covar = error_ellipse(real(squeeze(covar(1:plot_n_dim,1:plot_n_dim))),theta(1:plot_n_dim));
      set(h_covar,'Color',[1 0 0],'LineWidth',1);
      skill_list(ii).history(end+1).theta = theta;
      skill_list(ii).history(end).covar = covar;
      drawnow;
      
    end
    
    %--------------------------------------------------------------------------
    % see if the buffer is full - indicates that we should see if it's time
    % to split or not, and plot appropriately. If split, create two new
    % entries in the skill_list and delete the old entry
    %
    
    if length(c_skill.rollout_buffer) == c_skill.K
      for kk = 1 : c_skill.K;
        ps(kk,:) = c_skill.previous_experience(end - c_skill.K + kk).percept;
        cs(kk,:) = c_skill.previous_experience(end - c_skill.K + kk).cost;
      end
      
      %for each feature, subplot
      figure(fh);
      split_decision = [];
      split_feature = [];
      split_values = {};
      for i_f = 1:size(ps,2)
        rows = disp_n_skills;
        cols = 2*length(percept);
        i_row = ii;
        i_col = cols/2 + i_f;
        t = (i_row-1)*cols + i_col;
        if t < rows*cols
          subplot(rows,cols,t,'replace');
          [sd sf sv] = feature_split_cluster_costs(ps(:,i_f),cs,p_thresh,1,1);
        else
          [sd sf sv] = feature_split_cluster_costs(ps(:,i_f),cs,p_thresh);
        end
        split_decision(i_f) = sd;
        split_feature(i_f) = sf;
        split_values{i_f} = sv;
      end
      
      i_first = find(split_decision,1,'first');
      if ~isempty(i_first)
        [sub1 sub2] = copy_and_change(skill_list(ii),split_feature(i_first),split_values{i_first});
        
        skill_list(end+1).skill = sub1.skill;
        skill_list(end).conditions = sub1.conditions;
        skill_list(end).history = skill_list(ii).history;
        skill_list(end+1).skill = sub2.skill;
        skill_list(end).conditions = sub2.conditions;
        skill_list(end).history = skill_list(ii).history;
        skill_list(ii) = [];
      end

    end
    
  end
  
  
  %--------------------------------------------------------------------------
  %see if merging is needed
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
  drawnow
  %disp(count);
  
end



timestr = datestr(clock);
timestr(timestr == ' ') = '_';
timestr(timestr == ':') = '-';

save(timestr,'obj','percepts','tasks','task_solver','skill_list');

