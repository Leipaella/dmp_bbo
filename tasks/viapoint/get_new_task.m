
function [tasks, percepts, ntasks] = get_new_task(g, y0)

ntasks = 2;

task = task_viapoint([0.4 0.7],0.3);
task.id = 1;
tasks(1) = task;
percepts(1,1) = 0;
percepts(1,2) = 0;


task = task_viapoint([0.7 0.4],0.3);
task.id = 2;
tasks(2) = task;
percepts(2,1) = 1;
percepts(2,2) = 0;

%task = task_viapoint([0.45 0.7],0.3);
%task.id = 3;
%tasks(3) = task;
%percepts(3,1) = 1;
%percepts(3,2) = 1;

end