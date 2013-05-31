function [tasks percepts ntasks] = generate_two_tasks()

ntasks = 2;

%task 1 is a tall thin rectangular prism
task = task_arm_path();
task.id = 1;
task.filename = 'very_tall_square_rod.ttt';
tasks(1) = task;
percepts(1,:) = 0;


task = task_arm_path();
task.id = 2;
task.filename = 'laying_down_square_rod.ttt';
tasks(2) = task;
percepts(2,:) = 1;

end