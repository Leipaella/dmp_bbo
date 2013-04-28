function [tasks percepts ntasks] = generate_shape_tasks()
% Generate two tasks and percepts based on the eigenvalues of the object
% shape. Note: the initial eigenvals and eigenvecs are only important if
% the cost function relies on comparing the final orientation to the
% initial orientation.

ntasks = 2;

%task 1 is a tall thin rectangular prism
initial_eigenvals = [0.8 0.2];
initial_eigenvecs = [1 0; 0 1];
task = task_arm_path(initial_eigenvals, initial_eigenvecs);
task.id = 1;
tasks(1) = task;
percepts(1,:) = initial_eigenvals;

%task 2 is a wide short rectangular prism (same dimensions as above but on
%its side)
initial_eigenvals = [0.2 0.8];
task = task_arm_path(initial_eigenvals, initial_eigenvecs);
task.id = 2;
tasks(2) = task;
percepts(2,:) = initial_eigenvals;

end