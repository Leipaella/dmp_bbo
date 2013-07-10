
close all;
clearvars;
trial_name = '2_viapoint_tasks';
fh = figure(10);
n_skills_disp = 3;
goal_learning = 0;
n_samples_per_update = 30;
n_updates = 50;
disp_n_skills = 3;
n_dims = 1;

g = [1.0 1.0];
y0 = [0.0 0.0];
n_dofs = length(g);
 
evaluation_external_program = 0;
task_solver = task_viapoint_solver_dmp(g,y0,evaluation_external_program);

i_update = 0;
count = 0;


p_thresh = 0.5;

n_basis_functions = 2;
% Initialize the distributions
for dd=1:n_dofs
  distributions_init(dd).mean  = zeros(1,n_basis_functions);
  distributions_init(dd).covar = 5*eye(n_basis_functions);
end

obj = Skill('Viapoint',distributions_init);
obj.rollout_buffer = [];
obj.i_update = 0;
obj.K = n_samples_per_update;
obj.n_figs = 3;
obj.idx = 0;
count = 0;

%skill list
skill_list(1).conditions = {[]};
skill_list(1).skill = obj;
skill_list(1).history = [];


[tasks percepts n_tasks] = get_new_task(g,y0);

wh = waitbar(0,'Running Simulations');
t1 = clock;
while i_update < n_updates

  %--------------------------------------------------------------------------
  % Generate a task and percept
  
  p = randperm(n_tasks);
  r = ceil(n_tasks*rand(1,n_samples_per_update));
  r = sort(r);
  
  for i_instance = 1:n_samples_per_update
  
      fraction = count/(n_samples_per_update*n_updates);

      t2 = clock;
      diff = etime(t2,t1);
      secs_remaining = (diff/fraction)*(1-fraction);
      hours = floor(secs_remaining/3600);
      secs_remaining = secs_remaining - 3600*hours;
      mins = floor(secs_remaining/60);
      secs_remaining = secs_remaining - 60*mins;
      secs = round(secs_remaining);
      new_title = sprintf('%2dh %2dm %2ds remaining...',hours,mins,secs);
      waitbar(fraction,wh,new_title);
      
      task = tasks(r(i_instance));
      %percept = percepts(r(i_instance),:);
      percept = task.viapoint(1);



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
          clf
          subplot(rows,cols,t(:));
          
          hold on;
          %n_dims  = length(c_skill.distributions.mean);
          plot_n_dim = min(n_dims,2);
          for hist = 1:length(skill_list(ii).history)
            theta = skill_list(ii).history(hist).theta;
            covar = skill_list(ii).history(hist).covar;
            plot_n_dim = 2;
            h_covar = error_ellipse(real(squeeze(covar(1:plot_n_dim,1:plot_n_dim))),theta(1:plot_n_dim));
            set(h_covar,'Color',0.8*ones(1,3),'LineWidth',1);
          end
          %want to see the x-z plane, since that's the most interesting.
          %covar = diag([c_skill.distributions(7).covar c_skill.distributions(9).covar]);
          %theta = [c_skill.distributions(7).mean c_skill.distributions(9).mean];
          %covar = c_skill.distributions.covar;
          %theta = c_skill.distributions.mean;
          %plot_n_dim = 2;
          %h_covar = error_ellipse(real(squeeze(covar(1:plot_n_dim,1:plot_n_dim))),theta(1:plot_n_dim));
          %set(h_covar,'Color',[1 0 0],'LineWidth',1);
          %xlabel('Goal x-coordinate');
          %ylabel('Goal y-coordinate');
          %skill_list(ii).history(end+1).theta = theta;
          %skill_list(ii).history(end).covar = covar;
          samples = generate_samples(skill_list(ii).skill.distributions,1,1);
            cost_vars = task_solver.perform_rollouts(task,samples);
            task_solver.plot_rollouts(gca,task,cost_vars)
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
            pause
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
  i_update = i_update + 1;
end

close(wh);
%task_solver.close_sim();
timestr = datestr(clock);
timestr(timestr == ' ') = '_';
timestr(timestr == ':') = '-';

figure
for ii = 1:length(tasks)
    hold on
    task = tasks(ii);
    plot_n_dofs = min(n_dofs,3);
    if (isfield(task_solver,'plot_rollouts'))
      subplot(plot_n_dofs,4,1:4:plot_n_dofs*4)
      percept = task.viapoint(1);
      indices = find_applicable_skills(percept, skill_list);
      first = min(indices);
      skill = skill_list(first).skill;
      samples = generate_samples(skill.distributions,1,1);
      cost_vars = task_solver.perform_rollouts(task,samples);
      task_solver.plot_rollouts(gca,task,cost_vars)
      title('Visualization of roll-outs')
    end
    plotlearninghistory(skill.learning_history);
end




%save(timestr,'percepts','tasks','task_solver','skill_list','n_tasks','n_samples_per_update');


