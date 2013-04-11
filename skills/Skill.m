classdef Skill
  properties
    name;
    K;
    idx;
    distributions;
    rollout_buffer; %rollout.dmp_parameters_sample, rollout.sensation, rollout.cost
    i_update=0;
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
        
        %label = obj.tree.eval(percept);
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
      
      K=obj.K;
      plot_me = 0;
      n_dofs = size(obj.distributions,2);
      mean = obj.distributions.mean;
      n_dims = size(mean,2);

      sensation = [];
      % check precondition
      if precondition_holds(obj, sensation, percept)
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
        rollout.cost = costs;
        obj.rollout_buffer{end+1} = rollout;
        
        %if rollout buffer is full, update distributions and clear buffer
        if(length(obj.rollout_buffer)>K)
          %reshape the rollouts to work nicely with the
          %update_distributions function
          for ii = 1:length(obj.rollout_buffer)
            s(:,ii,:) = squeeze(obj.rollout_buffer{ii}.dmp_parameters_sample)';
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
    
        if mod(length(obj.previous_experience),obj.K) == 0
           fig = obj.idx*obj.n_figs + 2;
           %reformat most recent K samples (i.e. all from the same dist)
           for ii = 1 : obj.K;
             percepts(ii,:) = obj.previous_experience(end - obj.K + ii).percept;
             costs(ii,:) = obj.previous_experience(end - obj.K + ii).cost;
           end
           [split_decision split_feature split_value] = feature_split_cluster_costs(percepts,costs,0.09,fig);
           %[split_decision split_feature split_value] = feature_split_sliding(percepts,costs,0.09,fig);
           
           split_decision = false;
           if split_decision
             %create a tree to make the decision we want... hacking matlab
             %yuck
             percept1 = zeros([1 length(percepts(1,:))]);
             percept2 = percept1;
             %
             %percept1(split_feature) = split_value - 1;
             %percept2(split_feature) = split_value + 1;
             %labels = [1;2];
             %tree = classregtree([percept1;percept2],labels,'method','classification');
             
             obj.subskills = obj;
             obj.subskills.idx = obj.idx + 1;
             obj.subskills(2) = obj;
             obj.subskills(2).idx = obj.idx + 2;
             obj.tree.split_feature = split_feature;
             obj.tree.split_value = split_value;
             
             
           end
          
        end

        %after a certain number of samples are taken, it's time to examine 
        %if the skill should be split or not.
        
%         if mod(length(obj.previous_experience),60) == 0
%           fig = obj.idx*obj.n_figs + 2;
%           
%           
%           [split_decision split_feature split_value] = split_2D_gaussians(percepts,costs,fig);
%           
%          
%           if splitDecision == true
%             disp(['Took ' num2str(obj.i_update) ' updates to split']);
%             obj.tree = tree;
%             obj.subskills = Skill(strcat(obj.name, '_sub', num2str(1)),obj.distributions);
%             obj.subskills.idx = obj.idx + 1;
%             obj.subskills.n_figs = 3;
%             obj.subskills.previous_experience = [];
%             
%             %hard coded but need to make this parameterized for other
%             %problems.
%             %mean can start out the same, but need to encourage exploring
%             %more at first! Or else won't discover new techniques...
%             %obj.subskills.distributions.covar = diag([5 1000^2 1000^2]);
%             %obj.subskills.distributions.covar = 10^2;
%            %distributions(1).mean = [50 0];
%            distributions(1).covar = diag([10^2 (pi/2)^2]);
%             
%             for jj = 2:n_splits
%               obj.subskills(jj) = obj.subskills(jj-1);
%               obj.subskills(jj).name = strcat(obj.name, '_sub', num2str(jj));
%               obj.subskills(jj).idx = obj.subskills(jj-1).idx + 1;
%             end
%           end
%          
%        end
        
        
        % Plotting
        if obj.n_figs >= 1
          
          % Very difficult to see anything in the plots for many dofs
          plot_n_dofs = min(n_dofs,3);
          
          % Plot rollouts if the plot_rollouts function is available
          if (isfield(task_solver,'plot_rollouts'))
            %figure(obj.idx*obj.n_figs + 1)
            %subplot(plot_n_dofs,4,1:4:plot_n_dofs*4)
            %task_solver.plot_rollouts(gca,task_instance,cost_vars)
            %title('Visualization of roll-outs')
          end
          if(plot_me && 0)
            % Plot learning histories
            figure(obj.idx*obj.n_figs + 3)
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
        if percept(obj.tree.split_feature) < obj.tree.split_value
          obj.subskills(1) = solve_task_instance(obj.subskills(1),task_instance,task_solver,percept);
        else
          obj.subskills(2) = solve_task_instance(obj.subskills(2),task_instance,task_solver,percept);
        end
        
        %label = obj.tree.eval(percept);
        %obj.subskills(str2double(label{1})) = solve_task_instance(obj.subskills(str2double(label{1})),task_instance,task_solver, percept);
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
      obj.K = 100;

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