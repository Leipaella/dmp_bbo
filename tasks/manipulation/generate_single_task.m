function [tasks percepts ntasks] = generate_single_task()

ntasks = 1;

%task 1 is a tall thin rectangular prism
task = task_arm_path();
task.id = 1;
task.filename = 'very_tall_square_rod.ttt';
tasks(1) = task;
percepts(1,:) = 0;

end