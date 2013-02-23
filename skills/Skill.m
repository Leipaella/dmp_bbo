classdef Skill
  properties
    name;
    distributions;
    rollout_buffer; %rollout.dmp_parameters_sample, rollout.sensation, rollout.cost
    i_update;
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
    
    function obj = solve_task_instance(obj,task_instance)
      % Adds task_instance to the task_instance_buffer (useful when
      % executing in batch mode)

      %     - Sample dmp parameters from distribution
      %     - record sensation
      %     - Execute skill with parameters above, record all relevant vars
      %     - Determine cost, using task, given relevant variables recorded
      %     - put results in rollout_buffer
      %     - put results in previous experience
      
      K=20;
      plot_me = 1;
      samples = generate_samples(obj.distributions,K);
      sensation = [];
      precept = [];
      
      if precondition_holds(obj, sensation, precept)
        obj.i_update = obj.i_update + 1;
        costs = task_instance.perform_rollouts(task_instance,samples,plot_me);
        rollout.dmp_parameters_distributions = obj.distributions;
        rollout.dmp_parameters_sample = samples;
        rollout.cost = costs;
        obj.rollout_buffer{end+1} = rollout;
        [obj.distributions summary] = update_distributions(obj.distributions,samples,costs);
      end
      % if rollout buffer is full
      % update the distributions!
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

    end
    
    
  end
  
end


function obj = Skill_test_function

   n_dims = 2;
   n_dofs = 1;
   task = task_viapoint;
   for i_dof = 1:n_dofs
     distributions(i_dof).mean = ones(1,n_dims);
     distributions(i_dof).covar = 5*eye(size(task.theta_init,2));
   end

   obj = Skill('Test skill',distributions);
   obj.rollout_buffer = [];
   obj.i_update = 0;
   for ii = 1:10
     obj = obj.solve_task_instance(task);
   end

end