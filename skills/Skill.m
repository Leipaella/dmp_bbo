classdef Skill
  properties
    name;
    idx;
    distributions;
    rollout_buffer; %rollout.dmp_parameters_sample, rollout.sensation, rollout.cost
    i_update;
    previous_experience; %contains precept, sample, cost, and i_update
    tree;
    learning_history; %same structure as used in other locations
    n_figs; %for 1, just does learning history, for 2 it does cost distributions too
    
    % later previous_experience; %update number, rollout, current distribution
    subskills;
  end
  
  methods

    function holds = precondition_holds(obj, sensation, percept)
      % Inputs: sensation   raw input from camera
      %         percept     true data to extract from sensation
      % Outputs: true or false based on whether this skill is applicable,
      % given the sensation and percept
      
      holds = true; 
      
      if ~isempty(obj.tree) && ~isempty(obj.subskills)
        %do have subskills
        [label, score] = predict(obj.tree,percept);
        holds = false;
      end
    end
   
    
    function obj = solve_task_instance(obj,task_instance, task_solver, percept)
      % Adds task_instance to the task_instance_buffer (useful when
      % executing in batch mode)

      %     - Sample dmp parameters from distribution
      %     - record sensation
      %     - Execute skill with parameters above, record all relevant vars
      %     - Determine cost, using task, given relevant variables recorded
      %     - put results in rollout_buffer
      %     - put results in previous experience
      
      K=20;
      plot_me = 0;
      n_dofs = length(obj.distributions);

      sensation = [];
      % check precondition
      if precondition_holds(obj, sensation, percept)
        obj.i_update = obj.i_update + 1;
       
        %sample dmp parameters from distribution (1 at a time)
        samples = generate_samples(obj.distributions,1,0);
        
        %execute skill, record relevant cost variables
        cost_vars = task_solver.perform_rollouts(task_instance,samples);
        
        %determine cost, given the task and relevant cost variables
        costs = task_instance.cost_function(task_instance,cost_vars);
        
        %put results in rollout buffer
        rollout.dmp_parameters_distributions = obj.distributions;
        rollout.dmp_parameters_sample = samples;
        rollout.cost = costs;
        obj.rollout_buffer{end+1} = rollout;
        
        %if rollout buffer is full, update distributions and clear buffer
        if(length(obj.rollout_buffer)>K)
          %reshape the rollouts to work nicely with the
          %update_distributions function
          for ii = 1:length(obj.rollout_buffer)
            s(:,ii,:) = squeeze(obj.rollout_buffer{ii}.dmp_parameters_sample);
            c(ii,:) = obj.rollout_buffer{ii}.cost;
          end
          
          %update the distributions
          [obj.distributions summary] = update_distributions(obj.distributions,s,c);
          
          %add to learning history to make a nice plot
          if isempty(obj.learning_history)
            obj.learning_history = summary;
          else
            obj.learning_history(end+1) = summary;
          end
          plot_me = 1; %turn plotting on for the distributions
          
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
     
        
        %if more than, say, 50 samples taken, time to examine if it's worth
        %splitting the skill.
        
        if mod(length(obj.previous_experience),50) == 0
          obj.visualize_previous_experience();
          [splitDecision tree] = cluster_costs(obj);
          if splitDecision == true
            obj.tree = tree;
          end
        end
        
        
        % Plotting
        if obj.n_figs >= 1
          figure(obj.idx*obj.n_figs + 1)
          
          % Very difficult to see anything in the plots for many dofs
          plot_n_dofs = min(n_dofs,3);
          
          % Plot rollouts if the plot_rollouts function is available
          if (isfield(task_solver,'plot_rollouts'))
            subplot(plot_n_dofs,4,1:4:plot_n_dofs*4)
            task_solver.plot_rollouts(gca,task_instance,cost_vars)
            title('Visualization of roll-outs')
          end
          if(plot_me)
            % Plot learning histories
            if (obj.i_update>0 && ~isempty(obj.learning_history))
              plotlearninghistory(obj.learning_history);
              if (isfield(task_instance,'plotlearninghistorycustom'))
                figure(11)
                task_instance.plotlearninghistorycustom(obj.learing_history)
              end
            end
            
            plot_me = 0;
          end
        end
      else %end if ( precondition_holds )
        [label, costs] = predict(obj.tree,percept);
        obj.subskills(label) = solve_task_instance(obj.subskills(label),task_intance,task_solver, percept);
      end
    end %end solve_task_instance
    
    function print(obj)
      %Prints out a list of current subskills
      disp(obj.name);
      for skill = obj.subskills
        disp(['  ' skill.name]);
      end
    end
        
    function obj = Skill(name, distributions)
      if(nargin == 0)
        obj = Skill_test_function();
        return;
      end
      obj.name = name;
      obj.distributions = distributions;
      obj.i_update = 0;

    end
    
    function visualize_previous_experience(obj)
      figure(obj.idx*obj.n_figs + 2)
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
   
   while obj.i_update < 400
     if(rand(1)>0.5)
       task = task_viapoint([0.4 0.7],0.3);
       percept = [1 rand([1 4])];
     else
       task = task_viapoint([0.7 0.4],0.3);
       percept = [0 rand([1 4])];
     end
     task_solver = task_viapoint_solver_dmp(g,y0,0);
     obj = obj.solve_task_instance(task,task_solver,percept);
     
   end

end