classdef Skill
  properties
    name;
    K;
    idx;
    distributions;
    rollout_buffer; %rollout.dmp_parameters_sample, rollout.sensation, rollout.cost
    i_update=0;
    previous_experience; %contains precept, sample, cost, and i_update
    condition;
    learning_history; %same structure as used in other locations
    n_figs; %for 1, just does learning history, for 2 it does cost distributions too

    % later previous_experience; %update number, rollout, current distribution
    subskills;
  end

  methods

    function obj = Skill(name, distributions, n_rollouts_per_update)
      if(nargin == 0)
        obj = Skill_test_function();
        return;
      end
      if(nargin<3)
        n_rollouts_per_update = 25;
      end
      obj.idx = 1;
      obj.name = name;
      obj.distributions = distributions;
      obj.i_update = 0;
      obj.K = n_rollouts_per_update;
      obj.n_figs = 0;
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


    function obj = solve_task_instance(obj,task_instance, task_solver, percept, goal_learning)
      fprintf('Solve task instance for %s\n',obj.name)

      % Adds task_instance to the task_instance_buffer (useful when
      % executing in batch mode)

      %     - Sample dmp parameters from distribution
      %     - record sensation
      %     - Execute skill with parameters above, record all relevant vars
      %     - Determine cost, using task, given relevant variables recorded
      %     - put results in rollout_buffer
      %     - put results in previous experience

      if nargin < 5, goal_learning = 0; end

      K=obj.K;
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
          fprintf('  => Going for subskill %s\n',obj.subskills(ss).name)
          obj.subskills(ss) = obj.subskills(ss).solve_task_instance(task_instance,task_solver,percept);
          return;
        end
      end
      fprintf('  =>No subskill is valid\n')
      
      % None of the subskill's preconditions held (or there were no subskills)
      % Therefore, do rollout within the current skill.
      
      obj.i_update = obj.i_update + 1;

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
      rollout.dmp_parameters_distributions = obj.distributions;
      rollout.dmp_parameters_sample = samples;
      rollout.cost_vars = cost_vars;
      rollout.cost = costs;
      rollout.task_instance = task_instance;
      obj.rollout_buffer{end+1} = rollout;

      %if rollout buffer is full, update distributions and clear buffer
      if (length(obj.rollout_buffer)>K)
        fprintf('Buffer is full (%d rollouts). Performing update for "%s".\n',K,obj.name);
        %reshape the rollouts to work nicely with the
        %update_distributions function
        for ii = 1:length(obj.rollout_buffer)
          s(:,ii,:) = squeeze(obj.rollout_buffer{ii}.dmp_parameters_sample);
          c(ii,:) = obj.rollout_buffer{ii}.cost;
        end

        %update parameters
        update_parameters.weighting_method    = 'CMA-ES';
        update_parameters.eliteness           = floor(K/2);
        update_parameters.covar_update        = 'PI-BB';
        update_parameters.covar_full          =       0;
        update_parameters.covar_learning_rate =       1;
        update_parameters.covar_bounds        =      [0.2 0.1];
        update_parameters.covar_scales        =       1;

        %update the distributions
        [obj.distributions summary] = update_distributions(obj.distributions,s,c,update_parameters);

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
            for ii = 1:length(obj.rollout_buffer)
              task_solver.plot_rollouts(gca,obj.rollout_buffer{ii}.task_instance,obj.rollout_buffer{ii}.cost_vars)
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
        obj.rollout_buffer = [];


      end




      %add to previous history!
      previous.percept = percept;
      previous.sample = samples;
      previous.cost = costs;
      previous.i = obj.i_update;
      %need to do this to initiallize as a struct array
      if isempty(obj.previous_experience)
        obj.previous_experience = previous;
      else
        obj.previous_experience(end+1) = previous;
      end

      if mod(length(obj.previous_experience),obj.K) == 0
        fig = obj.idx*obj.n_figs + 2;
        %reformat most recent K samples (i.e. all from the same dist)
        for ii = 1 : obj.K;
          percepts(ii,:) = obj.previous_experience(end - obj.K + ii).percept;
          costs(ii,:) = obj.previous_experience(end - obj.K + ii).cost;
        end
        [split_decision split_feature split_feature_ranges] = feature_split_dbscan(percepts,costs,0.09);

        if (split_decision)
          disp('Making subskills')
          subs1 = clone(obj);
          subs2 = clone(obj);
          obj.subskills          = subs1;
          obj.subskills(2)       = subs2;
          for ss=1:2
            obj.subskills(ss).subskills = [];
            obj.subskills(ss).idx  = 10*obj.idx + ss;
            obj.subskills(ss).name     = sprintf('%s_subskill%d',obj.name,obj.subskills(ss).idx);
            obj.subskills(ss).condition.split_feature = split_feature;
            obj.subskills(ss).condition.split_feature_range = split_feature_ranges(ss,:);
            obj.subskills(ss).rollout_buffer = [];
          end
          obj
          obj.subskills(1)
          obj.subskills(2)
        end

      end

    end %end solve_task_instance

    function print(obj)
      %Prints out a list of current subskills
      disp(obj.name);
      for skill = obj.subskills
        disp(['  ' skill.name]);
      end
    end


    function visualize_previous_experience(obj, fig)
      figure(fig)
      clf;
      hold on;
      for ii = 1:length(obj.previous_experience)
        if(obj.previous_experience(ii).percept(1))
          plot(obj.previous_experience(ii).cost(1),obj.previous_experience(ii).i,'rx');
        else
          plot(obj.previous_experience(ii).cost(1),obj.previous_experience(ii).i,'bx');
        end
      end
      xlabel('cost');
      ylabel('update number');
    end


  end

end


function obj = Skill_test_function
% Randomly chooses to give a task that will either be:
% - a task_viapoint going through [0.4 0.7]
% - a task_viapoint going through [0.7 0.4]
% with equal probability.
% For each task seen, calls the function solve_task_instance
% Plots

close all;

n_dims = 2;
n_dofs = 2;
for i_dof = 1:n_dofs
  distributions(i_dof).mean = ones(1,n_dims);
  distributions(i_dof).covar = 5*eye(2);
end

g = [1.0 1.0];
y0 = [0.0 0.0];
obj = Skill('Test skill',distributions);
obj.rollout_buffer = [];
obj.i_update = 0;
obj.n_figs = 2;
obj.idx = 0;
count = 0;
while count < 800
  percept = rand([1 5]);
  if(percept(1)>0.5)
    task = task_viapoint([0.4 0.7],0.3);
  else
    task = task_viapoint([0.7 0.4],0.3);
  end
  task_solver = task_viapoint_solver_dmp(g,y0,0);
  obj = obj.solve_task_instance(task,task_solver,percept);
  count = count+1;
end

end