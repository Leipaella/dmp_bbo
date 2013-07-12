classdef Skill
  properties
    name;
    idx;
    distributions;
    n_rollouts;
    n_updates;

    rollout_buffer_for_update;
    n_rollouts_per_update;
    rollout_buffer_for_split;
    n_rollouts_per_split;

    condition;
    learning_history; %same structure as used in other locations
    update_parameters;
    
    subskills;
  end

  methods

    function obj = Skill(name, distributions, n_rollouts_per_update,update_parameters)
      if(nargin == 0)
        obj = Skill_test_function();
        return;
      end
      if(nargin<3)
        n_rollouts_per_update = 25;
      end
      if (nargin<4)
        update_parameters.weighting_method    = 'CMA-ES';
        update_parameters.eliteness           = floor(n_rollouts_per_update/2);
        update_parameters.covar_update        = 'PI-BB';
        update_parameters.covar_full          =       0;
        update_parameters.covar_learning_rate =       1;
        update_parameters.covar_bounds        =      [0.2 0.01];
        update_parameters.covar_scales        =       1;
      end

      obj.idx = 1;
      obj.name = name;
      obj.distributions = distributions;
      obj.update_parameters = update_parameters;
      obj.n_rollouts = 0;
      obj.n_updates = 0;
      obj.n_rollouts_per_update = n_rollouts_per_update;
      obj.n_rollouts_per_split = n_rollouts_per_update; % zzz
      obj.subskills = [];
      obj.condition = [];
    end

    function holds = precondition_holds(obj, sensation, percept)
      % Inputs: sensation   raw input from camera
      %         percept     true data to extract from sensation
      % Outputs: true or false based on whether this skill is applicable,
      % given the sensation and percept
      holds = true;
      if (~isempty(obj.condition))
        value = percept(obj.condition.split_feature);
        valid_range = obj.condition.split_feature_range;
        holds = (value>valid_range(1) && value<valid_range(2));
      end
    end


    function obj = solve_task_instance(obj,task_instance, task_solver, percept)
      %fprintf('Solve task instance for %s\n',obj.name)

      % Adds task_instance to the task_instance_buffer (useful when
      % executing in batch mode)

      %     - Sample dmp parameters from distribution
      %     - record sensation
      %     - Execute skill with parameters above, record all relevant vars
      %     - Determine cost, using task, given relevant variables recorded
      %     - put results in rollout_buffer_for_update
      %     - put results in previous experience

      if nargin < 5, goal_learning = 0; end

      plot_me = 0;
      n_dofs = size(obj.distributions,2);
      % Very difficult to see anything in the plots for many dofs
      plot_n_dofs = min(n_dofs,3);
      mean = obj.distributions.mean;
      n_dims = size(mean,2);

      sensation = [];
      
      % Try if a subskill precondition holds. If so, use the subskill.
      for ss=1:length(obj.subskills)
        %fprintf('  => Checking for subskill %d %d "%s"\n',ss,obj.subskills(ss).idx,obj.subskills(ss).name)
        if (obj.subskills(ss).precondition_holds(sensation, percept))
          %fprintf('  => Going for subskill %s\n',obj.subskills(ss).name)
          obj.subskills(ss) = obj.subskills(ss).solve_task_instance(task_instance,task_solver,percept);
          return;
        end
      end
      %fprintf('  =>No subskill is valid\n')
      
      % None of the subskill's preconditions held (or there were no subskills)
      % Therefore, do rollout within the current skill.
      obj.n_rollouts = obj.n_rollouts+ 1;

      %sample dmp parameters from distribution (1 at a time)
      if n_dims >1
        samples = generate_samples(obj.distributions,1,0);
      else
        samples = mvnrnd(obj.distributions.mean, obj.distributions.covar, 1);
      end

      %execute skill, record relevant cost variables
      cost_vars = task_solver.perform_rollouts(task_instance,samples);

      %determine cost, given the task and relevant cost variables
      costs = task_instance.cost_function(task_instance,cost_vars);

      %put results in rollout buffer
      rollout = Rollout(obj.distributions,samples,cost_vars,costs,task_instance,percept);
      obj.rollout_buffer_for_update{end+1} = rollout;
      obj.rollout_buffer_for_split{end+1}  = rollout;

      %if rollout buffer is full, update distributions and clear buffer
      if (length(obj.rollout_buffer_for_update)>obj.n_rollouts_per_update)
        %reshape the rollouts to work nicely with the
        %update_distributions function
        for ii = 1:length(obj.rollout_buffer_for_update)
          s(:,ii,:) = squeeze(obj.rollout_buffer_for_update{ii}.sample);
          c(ii,:) = obj.rollout_buffer_for_update{ii}.cost;
        end

        %update the distributions
        [obj.distributions summary] = update_distributions(obj.distributions,s,c,obj.update_parameters);
        obj.n_updates = obj.n_updates+ 1;
        
        fprintf('Performed update %d for "%s" because buffer is full (%d rollouts).\n',obj.n_updates,obj.name,obj.n_rollouts_per_update);

        %add to learning history to make a nice plot
        if isempty(obj.learning_history)
          obj.learning_history = summary;
        else
          obj.learning_history(end+1) = summary;
        end

        plot_me = 1; %turn plotting on for the distributions
        %------------------------------------------------------------------
        % Plotting
        if (plot_me)
          figure(obj.idx)

          % Plot rollouts if the plot_rollouts function is available
          if (isfield(task_solver,'plot_rollouts'))
            subplot(plot_n_dofs,4,1:4:plot_n_dofs*4)
            cla
            for ii = 1:length(obj.rollout_buffer_for_update)
              task_solver.plot_rollouts(gca,obj.rollout_buffer_for_update{ii}.task_instance,obj.rollout_buffer_for_update{ii}.cost_vars)
              hold on
            end
            title('Visualization of roll-outs')
          end

          % Plot learning histories
          plotlearninghistory(obj.learning_history);
          if (isfield(task_instance,'plotlearninghistorycustom'))
            figure(11)
            task_instance.plotlearninghistorycustom(obj.learning_history)
          end

        end

        %empty the rollout buffer
        obj.rollout_buffer_for_update = [];

      end

      if (length(obj.rollout_buffer_for_split)>obj.n_rollouts_per_split)
        %reformat most recent K samples (i.e. all from the same dist)
        for ii = 1:obj.n_rollouts_per_split;
          percepts(ii,:) = obj.rollout_buffer_for_split{end-obj.n_rollouts_per_split + ii}.percept;
          costs(ii,:) = obj.rollout_buffer_for_split{end-obj.n_rollouts_per_split + ii}.cost;
        end
        figure_handle = 0;
        N = ceil(0.4*obj.n_rollouts_per_split);
        [split_decision split_feature split_feature_ranges] = feature_split_dbscan(percepts,costs,N,figure_handle);
        % remove first element in the rollout buffer
        obj.rollout_buffer_for_split(1) = [];

        if (split_decision )
          %disp('Making subskills')
          % Problem with tree: may lead to same skills
          subs = clone(obj);
          subs(2) = clone(obj);
          for ss=1:2
            subs(ss).subskills = [];
            subs(ss).idx  = 10*obj.idx + ss;
            subs(ss).name     = sprintf('%s_subskill%d',obj.name,subs(ss).idx);
            subs(ss).condition.split_feature = split_feature;
            subs(ss).condition.split_feature_range = split_feature_ranges(ss,:);
            subs(ss).rollout_buffer_for_update = [];
            subs(ss).rollout_buffer_for_split  = [];
          end
          split_tree = true;
          if (split_tree)
            obj.subskills          = subs(1);
            obj.subskills(2)       = subs(2);
          else
            % For a list, you have to copy the conditions and extend them
          end
          fprintf('Split skill "%s" into subskills "%s" and "%s"\n',obj.name,subs(1).name,subs(2).name)
        end
      end

      
    end %end solve_task_instance

  end

end


function obj = Skill_test_function
% Randomly chooses to give a task that will either be:
% - a task_viapoint going through [0.4 0.7]
% - a task_viapoint going through [0.7 0.4]
% with equal probability.
% For each task seen, calls the function solve_task_instance
% Plots


task{1} = task_viapoint([0.4 0.7],0.25);
task{2} = task_viapoint([0.7 0.4],0.25);

g = [1.0 1.0];
y0 = [0.0 0.0];
task_solver = task_viapoint_solver_dmp(g,y0,0);

n_dims = 2;
n_dofs = 2;
for i_dof = 1:n_dofs
  distributions(i_dof).mean = ones(1,n_dims);
  distributions(i_dof).covar = 5*eye(2);
end
n_rollouts_per_update = 10;
obj = Skill('Test skill',distributions,n_rollouts_per_update);

n_rollouts = 200;
for i_rollout=1:n_rollouts
  percept = rand([1 5]);
  if(percept(1)>0.5)
    cur_task = task{1}
  else
    cur_task = task{2}
  end
  obj = obj.solve_task_instance(cur_task,task_solver,percept);
end

end