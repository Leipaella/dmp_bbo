
function [tasks, percepts, ntasks] = get_new_task(g, y0)

ntasks = 4;

task = task_viapoint([0.4 0.7],0.3);
task.id = 1;
tasks(1) = task;
percepts(1,:) = 0.4;


task = task_viapoint([0.45 0.7],0.3);
task.id = 2;
tasks(2) = task;
percepts(2,:) = 0.45;

task = task_viapoint([0.65 0.4],0.3);
task.id = 3;
tasks(3) = task;
percepts(3,:) = 0.65;

task = task_viapoint([0.6 0.4],0.3);
task.id = 4;
tasks(4) = task;
percepts(4,:) = 0.7;

end