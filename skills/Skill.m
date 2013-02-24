classdef Skill
  properties
    name;
    distributions;
    rollout_buffer; %rollout.dmp_parameters_sample, rollout.sensation, rollout.cost
    i_update;
    previous_experience;
    % later previous_experience; %update number, rollout, current distribution
    % later subskills;
  end
  
  methods

    function holds = precondition_holds(obj, sensation, percept)
      % Inputs: sensation   raw input from camera
      %         percept     true data to extract from sensation
      % Outputs: true or false based on whether this skill is applicable,
      % given the sensation and percept
      holds = true;      
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
      samples = generate_samples(obj.distributions,1,0);
      plot_me = 0;
      n_dofs = length(obj.distributions);

      sensation = [];
      
      if precondition_holds(obj, sensation, percept)
        obj.i_update = obj.i_update + 1;
        cost_vars = task_solver.perform_rollouts(task_instance,samples);
        costs = task_instance.cost_function(task_instance,cost_vars);
        %costs = task_instance.perform_rollouts(task_instance,samples,plot_me);
        rollout.dmp_parameters_distributions = obj.distributions;
        rollout.dmp_parameters_sample = samples;
        rollout.cost = costs;
        obj.rollout_buffer{end+1} = rollout;
        if(length(obj.rollout_buffer)>K)
          for ii = 1:length(obj.rollout_buffer)
            s(:,ii,:) = squeeze(obj.rollout_buffer{ii}.dmp_parameters_sample);
            c(ii,:) = obj.rollout_buffer{ii}.cost;
          end
          [obj.distributions summary] = update_distributions(obj.distributions,s,c);
          if isempty(obj.previous_experience)
            obj.previous_experience = summary;
          else
            obj.previous_experience(end+1) = summary;
          end
          plot_me = 1;
          obj.rollout_buffer = [];
        end
        
     
     % Plotting
     if(plot_me)
         figure(1)
         
         % Very difficult to see anything in the plots for many dofs
         plot_n_dofs = min(n_dofs,3);
         
         % Plot rollouts if the plot_rollouts function is available
         if (isfield(task_solver,'plot_rollouts'))
           subplot(plot_n_dofs,4,1:4:plot_n_dofs*4)
           task_solver.plot_rollouts(gca,task_instance,cost_vars)
           title('Visualization of roll-outs')
         end
         
         % Plot learning histories
         if (obj.i_update>0 && ~isempty(obj.previous_experience))
           plotlearninghistory(obj.previous_experience);
           if (isfield(task_instance,'plotlearninghistorycustom'))
             figure(11)
             task_instance.plotlearninghistorycustom(obj.previous_experience)
           end
         end
         
         plot_me = 0;
     end
      
      
        
      end
      
    end
    
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
   
   while obj.i_update < 400
     if(rand(1)>0.5)
       task = task_viapoint([0.4 0.7],0.3);
       percept = 1;
     else
       task = task_viapoint([0.7 0.4],0.3);
       percept = 0;
     end
     task_solver = task_viapoint_solver_dmp(g,y0,0);
     obj = obj.solve_task_instance(task,task_solver,percept);
     
   end

end