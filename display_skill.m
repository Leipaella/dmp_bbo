function display_skill(filename, fig)

%if no filename, find most recent
if nargin <1
  listing = dir('*.mat');
  for ii = 1:length(listing)
    dates(ii)=datenum(listing(ii).date);
  end
  [~,ind] = max(dates);
  filename = listing(ind).name;
end
load(filename);

if nargin < 2
  figure;
else
  figure(fig);
end

n_tasks = length(tasks);
n_task_per_row = ceil(sqrt(n_tasks));
for i_task = 1:n_tasks
  subplot(n_task_per_row,n_task_per_row,i_task);
  percept = percepts(i_task,:);
  task = tasks(i_task);
  obj2 = recursive(obj,percept);
  sample = obj2.distributions.mean;
  cost_vars = task_solver.perform_rollouts(task,sample);
  task_solver.plot_rollouts(gca,task,cost_vars);
 % solve_task_instance(obj,task,task_solver,percept);
end


end

function out = recursive(obj,percept)

if obj.precondition_holds(percept)
  out = obj;
else
  out = recursive(obj.subskills(1), percept);
  out = recursive(obj.subskills(2), percept);
end

end