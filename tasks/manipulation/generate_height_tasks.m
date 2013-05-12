function [tasks percepts ntasks] = generate_height_tasks()
% Generate two tasks and percepts 
% 
% task 1: tall thin rectangular prism
% task 2: short thin rectangular prism
%
% percept: the height of the object

ntasks = 2;

%task 1 is a tall thin rectangular prism
task = task_arm_path();
task.id = 1;
task.filename = 'tall_square_rod.ttt';
tasks(1) = task;
percepts(1,:) = 1;

%task 2 is the same as task 1 but half the height
task = task_arm_path();
task.id = 2;
task.filename = 'short_square_rod.ttt';
tasks(2) = task;
percepts(2,:) = 0;

end